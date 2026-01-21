# 📥 Guía de Importación de Recursos Azure a Terraform

Esta guía te ayudará a importar recursos existentes de Azure a Terraform de manera manual y controlada.

---

## 📋 Tabla de Contenidos

1. [¿Cuándo Usar Importación Manual?](#cuándo-usar-importación-manual)
2. [Prerequisitos](#prerequisitos)
3. [Flujo General de Importación](#flujo-general-de-importación)
4. [Método 1: Script Interactivo (Recomendado)](#método-1-script-interactivo-recomendado)
5. [Método 2: Importación Manual Paso a Paso](#método-2-importación-manual-paso-a-paso)
6. [Ejemplos por Tipo de Recurso](#ejemplos-por-tipo-de-recurso)
7. [Troubleshooting](#troubleshooting)
8. [Mejores Prácticas](#mejores-prácticas)

---

## 🎯 ¿Cuándo Usar Importación Manual?

Usa importación manual cuando:

- ✅ Tienes recursos creados manualmente en Azure
- ✅ Quieres migrar de portal/CLI a Infrastructure as Code
- ✅ Necesitas gestionar recursos legacy con Terraform
- ✅ Quieres recuperar recursos después de perder el tfstate
- ✅ Migraste recursos entre suscripciones

**NO uses importación cuando:**
- ❌ Los recursos fueron creados por otro stack de Terraform (usa `terraform state mv`)
- ❌ Quieres duplicar recursos (mejor usar módulos)

---

## 📦 Prerequisitos

### Software Requerido

```bash
# Verificar Azure CLI
az --version

# Verificar Terraform
terraform --version

# Verificar jq
jq --version
```

### Instalación si falta algo:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y azure-cli jq

# macOS
brew install azure-cli jq

# Terraform
# Descargar de https://www.terraform.io/downloads
```

### Login a Azure

```bash
az login
az account set --subscription "tu-subscripcion"
az account show
```

---

## 🔄 Flujo General de Importación

El proceso de importación tiene 4 pasos principales:

```
1. DESCUBRIR     → Identificar recursos existentes en Azure
   ↓
2. CONFIGURAR    → Escribir bloque Terraform del recurso
   ↓
3. IMPORTAR      → Ejecutar terraform import
   ↓
4. VALIDAR       → Verificar con terraform plan
```

### Diagrama del Flujo:

```
┌─────────────────────────────────────────────────────────────┐
│                     RECURSOS EN AZURE                        │
│  (Creados manualmente o por otros medios)                   │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ 1. DESCUBRIR
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  az resource list -g mi-rg                                  │
│  az vm show -g mi-rg -n mi-vm                               │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ 2. CONFIGURAR
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  main.tf o import.tf                                        │
│                                                              │
│  resource "azurerm_virtual_machine" "mi_vm" {               │
│    name                = "mi-vm"                            │
│    resource_group_name = "mi-rg"                            │
│    ...                                                       │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ 3. IMPORTAR
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  terraform import azurerm_virtual_machine.mi_vm \           │
│    /subscriptions/.../resourceGroups/mi-rg/...              │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ 4. VALIDAR
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  terraform plan                                              │
│  → Debe mostrar "No changes"                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Método 1: Script Interactivo (Recomendado)

Hemos creado un script que automatiza gran parte del proceso.

### Paso 1: Ejecutar el Script

```bash
cd /ruta/a/xpeterraform-azure
./scripts/import-azure-resources.sh
```

### Paso 2: Seguir el Wizard

El script te guiará interactivamente:

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Azure Resource Importer for Terraform             ║
║        Importación Manual de Recursos Existentes         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

🔍 Verificando dependencias...
✅ Todas las dependencias instaladas

🔐 Verificando sesión de Azure...
✅ Conectado a Azure
   Suscripción: Mi Suscripción Production
   ID: 12345678-1234-1234-1234-123456789012

📦 Seleccionar Resource Group...

Resource Groups disponibles:

  1) rg-production-eastus          [eastus]
  2) rg-development-westus         [westus]
  3) rg-shared-services            [eastus]

Selecciona el número del Resource Group: 1

✅ Resource Group seleccionado: rg-production-eastus

🎯 ¿Qué tipo de recurso deseas importar?

  1) Resource Group
  2) Virtual Network (VNet)
  3) Subnet
  4) Network Security Group (NSG)
  5) Virtual Machine (Linux)
  9) Storage Account
  ...
  0) Listar todos los recursos del RG

Selecciona una opción: 2
```

### Paso 3: Revisar la Configuración Generada

El script genera automáticamente:

```hcl
# Virtual Network: vnet-production
resource "azurerm_virtual_network" "vnet_production" {
  name                = "vnet-production"
  resource_group_name = "rg-production-eastus"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

  tags = {
    "environment" = "production"
    "managed-by"  = "terraform"
  }
}
```

### Paso 4: Copiar el Código a tu Archivo Terraform

```bash
# Copiar la configuración generada a import.tf o main.tf
nano import.tf  # Pegar el código generado
```

### Paso 5: Ejecutar el Comando de Importación

El script te muestra el comando:

```bash
terraform import azurerm_virtual_network.vnet_production \
  /subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-production-eastus/providers/Microsoft.Network/virtualNetworks/vnet-production
```

O permite ejecutarlo directamente:

```
¿Ejecutar importación ahora? (y/n): y
```

### Paso 6: Verificar

```bash
terraform plan
```

Debe mostrar:
```
No changes. Your infrastructure matches the configuration.
```

### Paso 7: Revisar el Log

El script genera un log automático:

```bash
cat import-log-20260121-143022.md
```

---

## 🔧 Método 2: Importación Manual Paso a Paso

Si prefieres hacerlo manualmente sin el script:

### Ejemplo Completo: Importar una VM

#### Paso 1: Descubrir el Recurso

```bash
# Listar VMs en el Resource Group
az vm list -g rg-production -o table

# Obtener detalles de la VM específica
az vm show -g rg-production -n vm-web-01 -o json
```

#### Paso 2: Obtener el Resource ID

```bash
# Obtener el ID completo
az vm show -g rg-production -n vm-web-01 --query id -o tsv
```

Resultado:
```
/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-production/providers/Microsoft.Compute/virtualMachines/vm-web-01
```

#### Paso 3: Escribir el Bloque Terraform

Crear o editar `import.tf`:

```hcl
resource "azurerm_linux_virtual_machine" "vm_web_01" {
  name                = "vm-web-01"
  resource_group_name = "rg-production"
  location            = "eastus"
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [
    "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-production/providers/Microsoft.Network/networkInterfaces/vm-web-01-nic"
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  tags = {
    environment = "production"
    managed-by  = "terraform"
  }
}
```

#### Paso 4: Inicializar Terraform (si es necesario)

```bash
terraform init
```

#### Paso 5: Importar el Recurso

```bash
terraform import azurerm_linux_virtual_machine.vm_web_01 \
  /subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-production/providers/Microsoft.Compute/virtualMachines/vm-web-01
```

Salida esperada:
```
azurerm_linux_virtual_machine.vm_web_01: Importing from ID "/subscriptions/12345678..."
azurerm_linux_virtual_machine.vm_web_01: Import prepared!
  Prepared azurerm_linux_virtual_machine for import
azurerm_linux_virtual_machine.vm_web_01: Refreshing state... [id=/subscriptions/...]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```

#### Paso 6: Ajustar la Configuración

```bash
terraform plan
```

Terraform mostrará las diferencias entre tu configuración y el estado real:

```diff
  # azurerm_linux_virtual_machine.vm_web_01 will be updated in-place
  ~ resource "azurerm_linux_virtual_machine" "vm_web_01" {
      ~ priority              = "Regular" -> null
      ~ provision_vm_agent    = true -> (known after apply)
        # ...
    }
```

Ajusta tu configuración hasta que `terraform plan` muestre:
```
No changes. Your infrastructure matches the configuration.
```

---

## 📚 Ejemplos por Tipo de Recurso

### 1. Resource Group

```bash
# Descubrir
az group show -n rg-production

# Configuración Terraform
resource "azurerm_resource_group" "production" {
  name     = "rg-production"
  location = "eastus"

  tags = {
    environment = "production"
  }
}

# Importar
terraform import azurerm_resource_group.production \
  /subscriptions/SUB-ID/resourceGroups/rg-production
```

### 2. Virtual Network

```bash
# Descubrir
az network vnet show -g rg-production -n vnet-prod

# Configuración Terraform
resource "azurerm_virtual_network" "prod" {
  name                = "vnet-prod"
  resource_group_name = "rg-production"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "production"
  }
}

# Importar
terraform import azurerm_virtual_network.prod \
  /subscriptions/SUB-ID/resourceGroups/rg-production/providers/Microsoft.Network/virtualNetworks/vnet-prod
```

### 3. Subnet

```bash
# Descubrir
az network vnet subnet show -g rg-production --vnet-name vnet-prod -n subnet-web

# Configuración Terraform
resource "azurerm_subnet" "web" {
  name                 = "subnet-web"
  resource_group_name  = "rg-production"
  virtual_network_name = "vnet-prod"
  address_prefixes     = ["10.0.1.0/24"]
}

# Importar
terraform import azurerm_subnet.web \
  /subscriptions/SUB-ID/resourceGroups/rg-production/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/subnet-web
```

### 4. Network Security Group

```bash
# Descubrir
az network nsg show -g rg-production -n nsg-web

# Configuración Terraform
resource "azurerm_network_security_group" "web" {
  name                = "nsg-web"
  resource_group_name = "rg-production"
  location            = "eastus"

  tags = {
    environment = "production"
  }
}

# Importar
terraform import azurerm_network_security_group.web \
  /subscriptions/SUB-ID/resourceGroups/rg-production/providers/Microsoft.Network/networkSecurityGroups/nsg-web

# NOTA: Las reglas se importan por separado
terraform import azurerm_network_security_rule.allow_https \
  /subscriptions/SUB-ID/resourceGroups/rg-production/providers/Microsoft.Network/networkSecurityGroups/nsg-web/securityRules/allow-https
```

### 5. Storage Account

```bash
# Descubrir
az storage account show -g rg-production -n mystorageaccount

# Configuración Terraform
resource "azurerm_storage_account" "main" {
  name                     = "mystorageaccount"
  resource_group_name      = "rg-production"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "production"
  }
}

# Importar
terraform import azurerm_storage_account.main \
  /subscriptions/SUB-ID/resourceGroups/rg-production/providers/Microsoft.Storage/storageAccounts/mystorageaccount
```

### 6. Key Vault

```bash
# Descubrir
az keyvault show -g rg-production -n kv-production

# Configuración Terraform
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-production"
  resource_group_name = "rg-production"
  location            = "eastus"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  tags = {
    environment = "production"
  }
}

# Importar
terraform import azurerm_key_vault.main \
  /subscriptions/SUB-ID/resourceGroups/rg-production/providers/Microsoft.KeyVault/vaults/kv-production
```

### 7. Managed Disk

```bash
# Descubrir
az disk show -g rg-production -n disk-data-01

# Configuración Terraform
resource "azurerm_managed_disk" "data" {
  name                 = "disk-data-01"
  resource_group_name  = "rg-production"
  location             = "eastus"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 512

  tags = {
    environment = "production"
  }
}

# Importar
terraform import azurerm_managed_disk.data \
  /subscriptions/SUB-ID/resourceGroups/rg-production/providers/Microsoft.Compute/disks/disk-data-01
```

### 8. Network Interface

```bash
# Descubrir
az network nic show -g rg-production -n vm-web-01-nic

# Configuración Terraform
resource "azurerm_network_interface" "web" {
  name                = "vm-web-01-nic"
  resource_group_name = "rg-production"
  location            = "eastus"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "production"
  }
}

# Importar
terraform import azurerm_network_interface.web \
  /subscriptions/SUB-ID/resourceGroups/rg-production/providers/Microsoft.Network/networkInterfaces/vm-web-01-nic
```

---

## 🔍 Troubleshooting

### Error: "Resource Already Managed"

```
Error: resource already managed by Terraform
```

**Solución:** El recurso ya está en el tfstate. Usa `terraform state list` para verificar.

```bash
terraform state list | grep mi_recurso
```

### Error: "Invalid Resource ID"

```
Error: Invalid import ID
```

**Solución:** Verifica el formato del Resource ID. Debe ser el ID completo ARM:

```bash
# Correcto
/subscriptions/SUB-ID/resourceGroups/RG/providers/Microsoft.Compute/virtualMachines/VM

# Incorrecto
virtualMachines/VM
```

### Error: "Configuration Doesn't Match"

Después de importar, `terraform plan` muestra muchos cambios.

**Solución:** Ajusta tu configuración iterativamente:

1. Importa el recurso
2. Ejecuta `terraform plan`
3. Ajusta la configuración para eliminar diferencias
4. Repite hasta que no haya cambios

**Tip:** Usa `terraform show` para ver el estado actual:

```bash
terraform show -json | jq '.values.root_module.resources[] | select(.address == "azurerm_virtual_machine.mi_vm")'
```

### Error: "Provider Not Configured"

```
Error: Provider not configured
```

**Solución:** Asegúrate de tener el provider configurado en `providers.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
  }
}

provider "azurerm" {
  features {}
}
```

### Recursos con Dependencias

Algunos recursos deben importarse en orden específico:

```
1. Resource Group
2. Virtual Network
3. Subnet
4. Network Interface
5. Virtual Machine
```

---

## ✅ Mejores Prácticas

### 1. Usa un Archivo Separado para Importaciones

```bash
# Crea import.tf para mantener separado
touch import.tf
```

Después de validar, mueve a `main.tf` o al archivo apropiado.

### 2. Documenta las Importaciones

Agrega comentarios:

```hcl
# Importado el 2026-01-21
# Recurso creado manualmente en 2025
# terraform import azurerm_resource_group.prod /subscriptions/.../rg-prod
resource "azurerm_resource_group" "prod" {
  name     = "rg-prod"
  location = "eastus"
}
```

### 3. Valida Antes de Commitear

```bash
# Siempre verifica que no haya cambios
terraform plan

# Debe mostrar
# No changes. Your infrastructure matches the configuration.
```

### 4. Usa Módulos para Recursos Importados

Si importas múltiples VMs similares, refactoriza a módulos:

```hcl
module "vm_web" {
  source = "./modules/virtual_machine"

  vm_name = "vm-web-01"
  # ...
}
```

### 5. Mantén un Log de Importaciones

Crea un archivo `IMPORTS.md`:

```markdown
# Log de Importaciones

## 2026-01-21

- Resource Group: rg-production
- Virtual Network: vnet-prod
- Subnets: subnet-web, subnet-app
- VMs: vm-web-01, vm-web-02

**Comando usado:**
- terraform import azurerm_resource_group.prod ...
```

### 6. Backup del State

Antes de importar muchos recursos:

```bash
# Backup del tfstate
cp terraform.tfstate terraform.tfstate.backup-$(date +%Y%m%d)
```

### 7. Importa Incrementalmente

No importes todo de una vez:

✅ **Recomendado:**
```
Día 1: Resource Groups
Día 2: Networks
Día 3: VMs
```

❌ **No recomendado:**
```
Día 1: TODO
```

---

## 📊 Tabla de Referencia Rápida

| Recurso | Tipo Terraform | Formato de ID |
|---------|----------------|---------------|
| Resource Group | `azurerm_resource_group` | `/subscriptions/SUB/resourceGroups/RG` |
| VNet | `azurerm_virtual_network` | `/subscriptions/SUB/resourceGroups/RG/providers/Microsoft.Network/virtualNetworks/VNET` |
| Subnet | `azurerm_subnet` | `/.../virtualNetworks/VNET/subnets/SUBNET` |
| NSG | `azurerm_network_security_group` | `/.../Microsoft.Network/networkSecurityGroups/NSG` |
| VM (Linux) | `azurerm_linux_virtual_machine` | `/.../Microsoft.Compute/virtualMachines/VM` |
| VM (Windows) | `azurerm_windows_virtual_machine` | `/.../Microsoft.Compute/virtualMachines/VM` |
| NIC | `azurerm_network_interface` | `/.../Microsoft.Network/networkInterfaces/NIC` |
| Disk | `azurerm_managed_disk` | `/.../Microsoft.Compute/disks/DISK` |
| Storage | `azurerm_storage_account` | `/.../Microsoft.Storage/storageAccounts/SA` |
| Key Vault | `azurerm_key_vault` | `/.../Microsoft.KeyVault/vaults/KV` |

---

## 🎯 Checklist de Importación

Usa este checklist para cada recurso:

- [ ] Descubrir recurso con Azure CLI
- [ ] Obtener Resource ID completo
- [ ] Escribir bloque Terraform con configuración mínima
- [ ] Ejecutar `terraform init` (si es necesario)
- [ ] Ejecutar `terraform import`
- [ ] Verificar importación exitosa
- [ ] Ejecutar `terraform plan`
- [ ] Ajustar configuración hasta "No changes"
- [ ] Documentar importación
- [ ] Commit del código

---

## 📞 Soporte

Si tienes problemas con la importación:

1. Revisa la [documentación oficial de Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
2. Busca el recurso específico en la documentación del provider
3. Contacta al equipo de infraestructura

---

## 🔗 Referencias

- [Terraform Import Documentation](https://www.terraform.io/docs/cli/import/index.html)
- [AzureRM Provider Import Guides](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
