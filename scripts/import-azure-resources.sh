#!/bin/bash
#
# Azure Resource Importer - Importación Manual de Recursos a Terraform
#
# Este script ayuda a importar recursos existentes de Azure a Terraform
# de manera interactiva y guiada.
#
# Uso: ./import-azure-resources.sh
#

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
IMPORT_LOG="import-log-$(date +%Y%m%d-%H%M%S).md"

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║        Azure Resource Importer for Terraform             ║"
    echo "║        Importación Manual de Recursos Existentes         ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Verificar dependencias
check_dependencies() {
    echo -e "${BLUE}🔍 Verificando dependencias...${NC}"

    local missing_deps=()

    if ! command -v az &> /dev/null; then
        missing_deps+=("azure-cli")
    fi

    if ! command -v terraform &> /dev/null; then
        missing_deps+=("terraform")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}❌ Faltan dependencias: ${missing_deps[*]}${NC}"
        echo ""
        echo "Instalar con:"
        echo "  - Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli"
        echo "  - Terraform: https://www.terraform.io/downloads"
        echo "  - jq: apt-get install jq (Linux) o brew install jq (macOS)"
        exit 1
    fi

    echo -e "${GREEN}✅ Todas las dependencias instaladas${NC}"
    echo ""
}

# Login a Azure
azure_login() {
    echo -e "${BLUE}🔐 Verificando sesión de Azure...${NC}"

    if ! az account show &> /dev/null; then
        echo -e "${YELLOW}⚠️  No hay sesión activa. Iniciando login...${NC}"
        az login
    fi

    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    local subscription_name=$(az account show --query name -o tsv)

    echo -e "${GREEN}✅ Conectado a Azure${NC}"
    echo -e "   Suscripción: ${CYAN}$subscription_name${NC}"
    echo -e "   ID: ${CYAN}$SUBSCRIPTION_ID${NC}"
    echo ""
}

# Seleccionar Resource Group
select_resource_group() {
    echo -e "${BLUE}📦 Seleccionar Resource Group...${NC}"
    echo ""

    # Listar Resource Groups
    echo "Resource Groups disponibles:"
    echo ""

    local rgs=($(az group list --query "[].name" -o tsv | sort))

    if [ ${#rgs[@]} -eq 0 ]; then
        echo -e "${RED}❌ No se encontraron Resource Groups${NC}"
        exit 1
    fi

    local i=1
    for rg in "${rgs[@]}"; do
        local location=$(az group show -n "$rg" --query location -o tsv)
        printf "%3d) %-40s [%s]\n" "$i" "$rg" "$location"
        ((i++))
    done

    echo ""
    read -p "Selecciona el número del Resource Group: " selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#rgs[@]}" ]; then
        echo -e "${RED}❌ Selección inválida${NC}"
        exit 1
    fi

    RESOURCE_GROUP="${rgs[$((selection-1))]}"
    echo -e "${GREEN}✅ Resource Group seleccionado: $RESOURCE_GROUP${NC}"
    echo ""
}

# Listar recursos del Resource Group
list_resources() {
    echo -e "${BLUE}📋 Recursos en $RESOURCE_GROUP:${NC}"
    echo ""

    az resource list -g "$RESOURCE_GROUP" --query "[].{Name:name, Type:type, Location:location}" -o table
    echo ""
}

# Menú de tipos de recursos
show_resource_type_menu() {
    echo -e "${BLUE}🎯 ¿Qué tipo de recurso deseas importar?${NC}"
    echo ""
    echo "  1) Resource Group"
    echo "  2) Virtual Network (VNet)"
    echo "  3) Subnet"
    echo "  4) Network Security Group (NSG)"
    echo "  5) Virtual Machine (Linux)"
    echo "  6) Virtual Machine (Windows)"
    echo "  7) Network Interface (NIC)"
    echo "  8) Managed Disk"
    echo "  9) Storage Account"
    echo " 10) Key Vault"
    echo " 11) Azure SQL Server"
    echo " 12) Azure SQL Database"
    echo " 13) Container Registry (ACR)"
    echo " 14) Container Instance (ACI)"
    echo " 15) Public IP"
    echo " 16) Route Table"
    echo " 17) VNet Peering"
    echo ""
    echo "  0) Listar todos los recursos del RG"
    echo "  q) Salir"
    echo ""
    read -p "Selecciona una opción: " resource_type_choice
}

# Generar configuración Terraform para Resource Group
generate_resource_group_config() {
    local rg_name="$1"
    local location=$(az group show -n "$rg_name" --query location -o tsv)
    local tags=$(az group show -n "$rg_name" --query tags -o json)

    cat << EOF

# Resource Group: $rg_name
resource "azurerm_resource_group" "$rg_name" {
  name     = "$rg_name"
  location = "$location"

  tags = $tags
}
EOF
}

# Generar configuración Terraform para VNet
generate_vnet_config() {
    local vnet_name="$1"
    local rg="$2"

    local vnet_data=$(az network vnet show -g "$rg" -n "$vnet_name" -o json)
    local location=$(echo "$vnet_data" | jq -r '.location')
    local address_space=$(echo "$vnet_data" | jq -r '.addressSpace.addressPrefixes[]' | paste -sd "," -)
    local tags=$(echo "$vnet_data" | jq '.tags')

    cat << EOF

# Virtual Network: $vnet_name
resource "azurerm_virtual_network" "$vnet_name" {
  name                = "$vnet_name"
  resource_group_name = "$rg"
  location            = "$location"
  address_space       = [$(echo "$address_space" | sed 's/,/", "/g' | sed 's/^/"/;s/$/"/' )]

  tags = $tags
}
EOF
}

# Generar configuración Terraform para Subnet
generate_subnet_config() {
    local subnet_name="$1"
    local vnet_name="$2"
    local rg="$3"

    local subnet_data=$(az network vnet subnet show -g "$rg" --vnet-name "$vnet_name" -n "$subnet_name" -o json)
    local address_prefix=$(echo "$subnet_data" | jq -r '.addressPrefix')

    cat << EOF

# Subnet: $subnet_name
resource "azurerm_subnet" "$subnet_name" {
  name                 = "$subnet_name"
  resource_group_name  = "$rg"
  virtual_network_name = "$vnet_name"
  address_prefixes     = ["$address_prefix"]
}
EOF
}

# Generar configuración Terraform para NSG
generate_nsg_config() {
    local nsg_name="$1"
    local rg="$2"

    local nsg_data=$(az network nsg show -g "$rg" -n "$nsg_name" -o json)
    local location=$(echo "$nsg_data" | jq -r '.location')
    local tags=$(echo "$nsg_data" | jq '.tags')

    cat << EOF

# Network Security Group: $nsg_name
resource "azurerm_network_security_group" "$nsg_name" {
  name                = "$nsg_name"
  resource_group_name = "$rg"
  location            = "$location"

  tags = $tags
}

# NOTA: Las reglas de seguridad se deben importar por separado
# Ver documentación para importar security_rule
EOF
}

# Generar configuración Terraform para VM Linux
generate_linux_vm_config() {
    local vm_name="$1"
    local rg="$2"

    local vm_data=$(az vm show -g "$rg" -n "$vm_name" -o json)
    local location=$(echo "$vm_data" | jq -r '.location')
    local vm_size=$(echo "$vm_data" | jq -r '.hardwareProfile.vmSize')
    local tags=$(echo "$vm_data" | jq '.tags')

    cat << EOF

# Linux Virtual Machine: $vm_name
resource "azurerm_linux_virtual_machine" "$vm_name" {
  name                = "$vm_name"
  resource_group_name = "$rg"
  location            = "$location"
  size                = "$vm_size"

  admin_username      = "azureuser"  # ACTUALIZAR

  network_interface_ids = [
    # COMPLETAR con el ID de la NIC
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"  # VERIFICAR
  }

  source_image_reference {
    publisher = "Canonical"  # VERIFICAR
    offer     = "UbuntuServer"  # VERIFICAR
    sku       = "18.04-LTS"  # VERIFICAR
    version   = "latest"
  }

  tags = $tags
}

# IMPORTANTE: Revisa los valores marcados con # VERIFICAR o # ACTUALIZAR
# Ejecuta: az vm show -g $rg -n $vm_name para obtener detalles completos
EOF
}

# Generar configuración Terraform para Storage Account
generate_storage_account_config() {
    local sa_name="$1"
    local rg="$2"

    local sa_data=$(az storage account show -g "$rg" -n "$sa_name" -o json)
    local location=$(echo "$sa_data" | jq -r '.location')
    local sku=$(echo "$sa_data" | jq -r '.sku.name')
    local kind=$(echo "$sa_data" | jq -r '.kind')
    local tags=$(echo "$sa_data" | jq '.tags')

    cat << EOF

# Storage Account: $sa_name
resource "azurerm_storage_account" "$sa_name" {
  name                     = "$sa_name"
  resource_group_name      = "$rg"
  location                 = "$location"
  account_tier             = "$(echo $sku | cut -d'_' -f1)"
  account_replication_type = "$(echo $sku | cut -d'_' -f2)"
  account_kind             = "$kind"

  tags = $tags
}
EOF
}

# Generar comando de import
generate_import_command() {
    local resource_type="$1"
    local resource_name="$2"
    local terraform_address="$3"
    local azure_id="$4"

    echo ""
    echo -e "${GREEN}📝 Comando de importación generado:${NC}"
    echo ""
    echo -e "${YELLOW}terraform import $terraform_address $azure_id${NC}"
    echo ""
}

# Importar Resource Group
import_resource_group() {
    echo -e "${BLUE}📦 Importar Resource Group${NC}"
    echo ""

    local rg_id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
    local tf_address="azurerm_resource_group.${RESOURCE_GROUP//-/_}"

    echo "Resource Group: $RESOURCE_GROUP"
    echo ""

    # Generar configuración
    echo -e "${CYAN}Configuración Terraform sugerida:${NC}"
    generate_resource_group_config "$RESOURCE_GROUP"
    echo ""

    # Generar comando
    generate_import_command "resource_group" "$RESOURCE_GROUP" "$tf_address" "$rg_id"

    # Guardar en log
    {
        echo "## Resource Group: $RESOURCE_GROUP"
        echo ""
        echo "**Comando de importación:**"
        echo '```bash'
        echo "terraform import $tf_address $rg_id"
        echo '```'
        echo ""
        echo "**Configuración Terraform:**"
        echo '```hcl'
        generate_resource_group_config "$RESOURCE_GROUP"
        echo '```'
        echo ""
    } >> "$IMPORT_LOG"

    read -p "¿Ejecutar importación ahora? (y/n): " execute
    if [[ "$execute" == "y" ]]; then
        terraform import "$tf_address" "$rg_id"
        echo -e "${GREEN}✅ Recurso importado exitosamente${NC}"
    fi
}

# Importar VNet
import_vnet() {
    echo -e "${BLUE}🌐 Importar Virtual Network${NC}"
    echo ""

    # Listar VNets
    local vnets=($(az network vnet list -g "$RESOURCE_GROUP" --query "[].name" -o tsv))

    if [ ${#vnets[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No se encontraron VNets en este Resource Group${NC}"
        return
    fi

    echo "VNets disponibles:"
    local i=1
    for vnet in "${vnets[@]}"; do
        printf "%3d) %s\n" "$i" "$vnet"
        ((i++))
    done
    echo ""

    read -p "Selecciona el número de VNet: " selection
    local vnet_name="${vnets[$((selection-1))]}"

    local vnet_id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$vnet_name"
    local tf_address="azurerm_virtual_network.${vnet_name//-/_}"

    # Generar configuración
    echo -e "${CYAN}Configuración Terraform sugerida:${NC}"
    generate_vnet_config "$vnet_name" "$RESOURCE_GROUP"
    echo ""

    # Generar comando
    generate_import_command "vnet" "$vnet_name" "$tf_address" "$vnet_id"

    # Guardar en log
    {
        echo "## Virtual Network: $vnet_name"
        echo ""
        echo "**Comando de importación:**"
        echo '```bash'
        echo "terraform import $tf_address $vnet_id"
        echo '```'
        echo ""
        echo "**Configuración Terraform:**"
        echo '```hcl'
        generate_vnet_config "$vnet_name" "$RESOURCE_GROUP"
        echo '```'
        echo ""
    } >> "$IMPORT_LOG"

    read -p "¿Ejecutar importación ahora? (y/n): " execute
    if [[ "$execute" == "y" ]]; then
        terraform import "$tf_address" "$vnet_id"
        echo -e "${GREEN}✅ VNet importada exitosamente${NC}"
    fi
}

# Importar Storage Account
import_storage_account() {
    echo -e "${BLUE}💾 Importar Storage Account${NC}"
    echo ""

    # Listar Storage Accounts
    local sas=($(az storage account list -g "$RESOURCE_GROUP" --query "[].name" -o tsv))

    if [ ${#sas[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No se encontraron Storage Accounts en este Resource Group${NC}"
        return
    fi

    echo "Storage Accounts disponibles:"
    local i=1
    for sa in "${sas[@]}"; do
        printf "%3d) %s\n" "$i" "$sa"
        ((i++))
    done
    echo ""

    read -p "Selecciona el número de Storage Account: " selection
    local sa_name="${sas[$((selection-1))]}"

    local sa_id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$sa_name"
    local tf_address="azurerm_storage_account.${sa_name//-/_}"

    # Generar configuración
    echo -e "${CYAN}Configuración Terraform sugerida:${NC}"
    generate_storage_account_config "$sa_name" "$RESOURCE_GROUP"
    echo ""

    # Generar comando
    generate_import_command "storage_account" "$sa_name" "$tf_address" "$sa_id"

    # Guardar en log
    {
        echo "## Storage Account: $sa_name"
        echo ""
        echo "**Comando de importación:**"
        echo '```bash'
        echo "terraform import $tf_address $sa_id"
        echo '```'
        echo ""
        echo "**Configuración Terraform:**"
        echo '```hcl'
        generate_storage_account_config "$sa_name" "$RESOURCE_GROUP"
        echo '```'
        echo ""
    } >> "$IMPORT_LOG"

    read -p "¿Ejecutar importación ahora? (y/n): " execute
    if [[ "$execute" == "y" ]]; then
        terraform import "$tf_address" "$sa_id"
        echo -e "${GREEN}✅ Storage Account importado exitosamente${NC}"
    fi
}

# Menú principal
main_menu() {
    while true; do
        show_resource_type_menu

        case $resource_type_choice in
            1)
                import_resource_group
                ;;
            2)
                import_vnet
                ;;
            9)
                import_storage_account
                ;;
            0)
                list_resources
                ;;
            q|Q)
                echo -e "${GREEN}👋 Saliendo...${NC}"
                echo ""
                echo -e "${CYAN}📄 Log de importación guardado en: $IMPORT_LOG${NC}"
                exit 0
                ;;
            *)
                echo -e "${YELLOW}⚠️  Opción en desarrollo. Por ahora solo están disponibles:${NC}"
                echo "   1) Resource Group"
                echo "   2) Virtual Network"
                echo "   9) Storage Account"
                echo "   0) Listar recursos"
                echo ""
                ;;
        esac

        echo ""
        read -p "Presiona Enter para continuar..."
        clear
        print_banner
    done
}

# Main
main() {
    clear
    print_banner

    check_dependencies
    azure_login
    select_resource_group

    # Iniciar log
    {
        echo "# Log de Importación de Recursos Azure"
        echo ""
        echo "**Fecha:** $(date)"
        echo "**Suscripción:** $SUBSCRIPTION_ID"
        echo "**Resource Group:** $RESOURCE_GROUP"
        echo ""
        echo "---"
        echo ""
    } > "$IMPORT_LOG"

    main_menu
}

main "$@"
