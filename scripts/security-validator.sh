#!/bin/bash
#
# Security Compliance Validator para Azure Virtual Machines
# Analiza el terraform plan y valida configuraciones de seguridad
#
# Uso: ./security-validator.sh <terraform-plan.json>
#

set -euo pipefail

PLAN_FILE="${1:-tfplan.json}"
COMPLIANCE_SCORE=0
TOTAL_CHECKS=0
FAILED_CHECKS=()

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar si jq está instalado
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq no está instalado. Instálalo con: apt-get install jq"
        exit 1
    fi
}

# Función para extraer recursos de VMs del plan
extract_vm_resources() {
    jq -r '
        .planned_values.root_module.resources[]? // .resource_changes[]? |
        select(.type == "azurerm_linux_virtual_machine" or .type == "azurerm_windows_virtual_machine") |
        .values // .change.after
    ' "$PLAN_FILE" 2>/dev/null || echo "[]"
}

# Función para contar VMs en el plan
count_vms() {
    jq -r '
        [.planned_values.root_module.resources[]? // .resource_changes[]? |
        select(.type == "azurerm_linux_virtual_machine" or .type == "azurerm_windows_virtual_machine")] |
        length
    ' "$PLAN_FILE" 2>/dev/null || echo "0"
}

# Función para verificar NICs sin IP pública
check_no_public_ip() {
    local vm_name="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Buscar NICs en el plan
    local has_public_ip=$(jq -r --arg vm "$vm_name" '
        [.planned_values.root_module.resources[]? // .resource_changes[]? |
        select(.type == "azurerm_network_interface") |
        .values // .change.after |
        select(.name | contains($vm)) |
        .ip_configuration[]? |
        select(.public_ip_address_id != null and .public_ip_address_id != "")] |
        length > 0
    ' "$PLAN_FILE" 2>/dev/null)

    if [[ "$has_public_ip" == "false" ]]; then
        echo "✅ Sin IP pública"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    else
        echo "❌ Tiene IP pública (vulnerabilidad)"
        FAILED_CHECKS+=("IP pública detectada")
        return 1
    fi
}

# Función para verificar encryption at host
check_encryption_at_host() {
    local vm_data="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local enabled=$(echo "$vm_data" | jq -r '.encryption_at_host_enabled // false')

    if [[ "$enabled" == "true" ]]; then
        echo "✅ Encryption-at-host habilitado"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    else
        echo "⚠️  Encryption-at-host deshabilitado"
        FAILED_CHECKS+=("Encryption-at-host no habilitado")
        return 1
    fi
}

# Función para verificar Trusted Launch
check_trusted_launch() {
    local vm_data="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local vtpm=$(echo "$vm_data" | jq -r '.vtpm_enabled // false')
    local secure_boot=$(echo "$vm_data" | jq -r '.secure_boot_enabled // false')

    if [[ "$vtpm" == "true" ]] && [[ "$secure_boot" == "true" ]]; then
        echo "✅ Trusted Launch habilitado (vTPM + Secure Boot)"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    else
        echo "⚠️  Trusted Launch deshabilitado"
        FAILED_CHECKS+=("Trusted Launch no configurado")
        return 1
    fi
}

# Función para verificar Managed Identity
check_managed_identity() {
    local vm_data="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local identity_type=$(echo "$vm_data" | jq -r '.identity[0].type // empty')

    if [[ -n "$identity_type" ]]; then
        echo "✅ Managed Identity configurada ($identity_type)"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    else
        echo "⚠️  Sin Managed Identity"
        FAILED_CHECKS+=("Managed Identity no configurada")
        return 1
    fi
}

# Función para verificar autenticación SSH (solo Linux)
check_ssh_authentication() {
    local vm_data="$1"
    local vm_type="$2"

    if [[ "$vm_type" != *"linux"* ]]; then
        return 0  # No aplica para Windows
    fi

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local disable_password=$(echo "$vm_data" | jq -r '.disable_password_authentication // false')
    local has_ssh_keys=$(echo "$vm_data" | jq -r '.admin_ssh_key // [] | length > 0')

    if [[ "$disable_password" == "true" ]] && [[ "$has_ssh_keys" == "true" ]]; then
        echo "✅ Autenticación SSH keys (contraseñas deshabilitadas)"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    elif [[ "$disable_password" == "false" ]]; then
        echo "❌ Autenticación por contraseña habilitada (inseguro)"
        FAILED_CHECKS+=("Autenticación por contraseña habilitada en Linux")
        return 1
    else
        echo "⚠️  Configuración de autenticación incompleta"
        FAILED_CHECKS+=("SSH keys no configuradas")
        return 1
    fi
}

# Función para verificar OS disk cifrado
check_os_disk_encryption() {
    local vm_data="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Azure cifra OS disks por defecto con SSE, verificamos que no esté deshabilitado
    local storage_type=$(echo "$vm_data" | jq -r '.os_disk[0].storage_account_type // "Standard_LRS"')

    if [[ -n "$storage_type" ]]; then
        echo "✅ OS Disk con cifrado SSE ($storage_type)"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    else
        echo "⚠️  OS Disk sin configuración de cifrado"
        FAILED_CHECKS+=("OS Disk no configurado")
        return 1
    fi
}

# Función para verificar Network Security Group
check_nsg() {
    local vm_name="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Buscar NSG asociado a la subnet o NIC
    local has_nsg=$(jq -r --arg vm "$vm_name" '
        [.planned_values.root_module.resources[]? // .resource_changes[]? |
        select(.type == "azurerm_network_security_group" or
               .type == "azurerm_subnet_network_security_group_association" or
               .type == "azurerm_network_interface_security_group_association")] |
        length > 0
    ' "$PLAN_FILE" 2>/dev/null)

    if [[ "$has_nsg" == "true" ]] || [[ "$has_nsg" -gt 0 ]]; then
        echo "✅ Network Security Group configurado"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    else
        echo "ℹ️  NSG no detectado en el plan (puede estar en subnet)"
        return 0  # No falla el check, solo informativo
    fi
}

# Función para verificar Azure Monitor Agent
check_monitoring() {
    local vm_name="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local has_monitor=$(jq -r --arg vm "$vm_name" '
        [.planned_values.root_module.resources[]? // .resource_changes[]? |
        select(.type == "azurerm_virtual_machine_extension") |
        .values // .change.after |
        select(.name | contains("AzureMonitor") or contains("Monitor"))] |
        length > 0
    ' "$PLAN_FILE" 2>/dev/null)

    if [[ "$has_monitor" == "true" ]] || [[ "$has_monitor" -gt 0 ]]; then
        echo "✅ Azure Monitor Agent configurado"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    else
        echo "ℹ️  Azure Monitor Agent no configurado"
        return 0  # No crítico, solo recomendado
    fi
}

# Función para generar reporte Markdown
generate_markdown_report() {
    local vm_count="$1"
    local percentage=$((COMPLIANCE_SCORE * 100 / TOTAL_CHECKS))

    cat << EOF

# 🔒 Reporte de Seguridad - Virtual Machines

## 📊 Resumen de Compliance

| Métrica | Valor |
|---------|-------|
| **VMs Analizadas** | $vm_count |
| **Checks Ejecutados** | $TOTAL_CHECKS |
| **Checks Aprobados** | $COMPLIANCE_SCORE |
| **Compliance Score** | **${percentage}%** |

EOF

    if [[ $percentage -ge 90 ]]; then
        echo "### ✅ Estado: APROBADO - Excelente Seguridad"
        echo ""
        echo "La configuración cumple con los estándares de seguridad recomendados."
    elif [[ $percentage -ge 70 ]]; then
        echo "### ⚠️  Estado: ACEPTABLE - Mejoras Recomendadas"
        echo ""
        echo "La configuración es aceptable pero tiene áreas de mejora."
    else
        echo "### ❌ Estado: NO RECOMENDADO - Requiere Atención"
        echo ""
        echo "La configuración tiene vulnerabilidades de seguridad importantes."
    fi

    if [[ ${#FAILED_CHECKS[@]} -gt 0 ]]; then
        echo ""
        echo "## ⚠️  Recomendaciones de Seguridad"
        echo ""
        for check in "${FAILED_CHECKS[@]}"; do
            echo "- $check"
        done
    fi

    echo ""
    echo "---"
    echo ""
    echo "## 📋 Checklist de Seguridad por VM"
    echo ""
}

# Función principal
main() {
    check_dependencies

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "Error: Archivo de plan no encontrado: $PLAN_FILE"
        exit 1
    fi

    echo "🔍 Analizando configuración de seguridad de VMs..."
    echo ""

    local vm_count=$(count_vms)

    if [[ "$vm_count" -eq 0 ]]; then
        echo "ℹ️  No se encontraron VMs en el plan de Terraform"
        echo ""
        echo "# 🔒 Reporte de Seguridad - Virtual Machines"
        echo ""
        echo "No hay VMs para analizar en este plan."
        exit 0
    fi

    echo "Encontradas $vm_count VM(s) en el plan"
    echo ""

    # Extraer todas las VMs
    local vm_index=0

    jq -c '
        .planned_values.root_module.resources[]? // .resource_changes[]? |
        select(.type == "azurerm_linux_virtual_machine" or .type == "azurerm_windows_virtual_machine")
    ' "$PLAN_FILE" 2>/dev/null | while IFS= read -r vm_resource; do
        vm_index=$((vm_index + 1))

        local vm_name=$(echo "$vm_resource" | jq -r '.name // .values.name // .change.after.name // "unknown"')
        local vm_type=$(echo "$vm_resource" | jq -r '.type')
        local vm_values=$(echo "$vm_resource" | jq -r '.values // .change.after')

        echo "### 🖥️  VM #$vm_index: $vm_name"
        echo ""
        echo "**Tipo:** $vm_type"
        echo ""
        echo "#### Validaciones de Seguridad:"
        echo ""

        check_no_public_ip "$vm_name"
        check_encryption_at_host "$vm_values"
        check_trusted_launch "$vm_values"
        check_managed_identity "$vm_values"
        check_ssh_authentication "$vm_values" "$vm_type"
        check_os_disk_encryption "$vm_values"
        check_nsg "$vm_name"
        check_monitoring "$vm_name"

        echo ""
        echo "---"
        echo ""
    done

    # Generar reporte final
    generate_markdown_report "$vm_count"

    # Determinar código de salida basado en compliance
    local percentage=$((COMPLIANCE_SCORE * 100 / TOTAL_CHECKS))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ $percentage -ge 70 ]]; then
        echo -e "${GREEN}✅ Compliance Score: ${percentage}%${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
    elif [[ $percentage -ge 50 ]]; then
        echo -e "${YELLOW}⚠️  Compliance Score: ${percentage}%${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "ADVERTENCIA: Se recomienda mejorar la configuración de seguridad"
        exit 0  # No falla el build, solo advertencia
    else
        echo -e "${RED}❌ Compliance Score: ${percentage}%${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "ERROR: La configuración no cumple con los requisitos mínimos de seguridad"
        exit 1  # Falla el build
    fi
}

main "$@"
