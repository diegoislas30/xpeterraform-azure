# Scripts de Seguridad y Automatización

Este directorio contiene scripts auxiliares para validación de seguridad y automatización de operaciones de infraestructura.

---

## 🔒 Security Validator (`security-validator.sh`)

Script que valida la configuración de seguridad de Virtual Machines en el plan de Terraform antes del deployment.

### Características

- ✅ Análisis automático del terraform plan JSON
- ✅ Validación de múltiples checkpoints de seguridad
- ✅ Generación de reporte en Markdown para GitHub Actions
- ✅ Cálculo de compliance score
- ✅ Integración con workflows de CI/CD

### Validaciones de Seguridad

El script verifica los siguientes puntos de seguridad en cada VM:

#### 🔴 CRÍTICO

| Check | Descripción | Impacto |
|-------|-------------|---------|
| **Sin IP Pública** | La VM no debe tener IP pública asignada | Alta vulnerabilidad de exposición |
| **SSH Keys (Linux)** | Linux VMs deben usar SSH keys, no contraseñas | Acceso no autorizado |

#### 🟡 ALTA PRIORIDAD

| Check | Descripción | Impacto |
|-------|-------------|---------|
| **Encryption-at-host** | Cifrado en el host habilitado | Protección de datos en reposo |
| **Trusted Launch** | vTPM y Secure Boot habilitados | Protección contra boot kits |
| **Managed Identity** | Identity configurada para evitar credenciales | Gestión de secretos |
| **OS Disk Encryption** | Sistema operativo cifrado con SSE | Protección de datos |

#### 🟢 RECOMENDADO

| Check | Descripción | Impacto |
|-------|-------------|---------|
| **Network Security Group** | NSG aplicado a NIC o subnet | Filtrado de tráfico |
| **Azure Monitor Agent** | Monitoreo y observabilidad | Detección de amenazas |

### Uso

#### Ejecución Manual

```bash
# 1. Generar plan de Terraform en formato JSON
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# 2. Ejecutar validador
./scripts/security-validator.sh tfplan.json
```

#### Salida de Ejemplo

```markdown
🔍 Analizando configuración de seguridad de VMs...

Encontradas 2 VM(s) en el plan

### 🖥️  VM #1: vm-ubuntu-web-01

**Tipo:** azurerm_linux_virtual_machine

#### Validaciones de Seguridad:

✅ Sin IP pública
✅ Encryption-at-host habilitado
✅ Trusted Launch habilitado (vTPM + Secure Boot)
✅ Managed Identity configurada (SystemAssigned)
✅ Autenticación SSH keys (contraseñas deshabilitadas)
✅ OS Disk con cifrado SSE (Premium_LRS)
✅ Network Security Group configurado
⚠️  Azure Monitor Agent no configurado

---

# 🔒 Reporte de Seguridad - Virtual Machines

## 📊 Resumen de Compliance

| Métrica | Valor |
|---------|-------|
| **VMs Analizadas** | 2 |
| **Checks Ejecutados** | 16 |
| **Checks Aprobados** | 14 |
| **Compliance Score** | **87%** |

### ✅ Estado: APROBADO - Excelente Seguridad

La configuración cumple con los estándares de seguridad recomendados.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Compliance Score: 87%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Códigos de Salida

| Código | Compliance | Significado | Acción en CI/CD |
|--------|------------|-------------|-----------------|
| **0** | ≥ 70% | Configuración aprobada | ✅ Continua el workflow |
| **0** | 50-69% | Configuración aceptable con warnings | ⚠️  Muestra advertencias |
| **1** | < 50% | Configuración rechazada | ❌ Falla el workflow |

### Integración con GitHub Actions

El script está integrado en el workflow `.github/workflows/iac.yml`:

```yaml
- name: 🔒 Validación de Seguridad de VMs
  if: success()
  continue-on-error: false
  run: |
    chmod +x ./scripts/security-validator.sh
    ./scripts/security-validator.sh tfplan.json > security-report.md
    cat security-report.md >> $GITHUB_STEP_SUMMARY
```

### Workflow de Aprobación

1. **Developer**: Crea PR con cambios de infraestructura
2. **GitHub Actions**: Ejecuta `terraform plan`
3. **Security Validator**: Analiza el plan y genera reporte
4. **Step Summary**: Muestra reporte en la UI de GitHub Actions
5. **Approver**: Revisa el compliance score y detalles de seguridad
6. **Aprobación Manual**: Si compliance ≥ 70%, puede aprobar
7. **Terraform Apply**: Se ejecuta solo después de aprobación

### Personalización

#### Modificar Threshold de Compliance

Editar líneas 312-330 en `security-validator.sh`:

```bash
# Cambiar threshold mínimo de 70% a 80%
if [[ $percentage -ge 80 ]]; then
    echo "✅ Compliance Score: ${percentage}%"
    exit 0
```

#### Agregar Nuevas Validaciones

Agregar función en `security-validator.sh`:

```bash
# Función para verificar feature X
check_feature_x() {
    local vm_data="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local enabled=$(echo "$vm_data" | jq -r '.feature_x_enabled // false')

    if [[ "$enabled" == "true" ]]; then
        echo "✅ Feature X habilitado"
        COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
        return 0
    else
        echo "❌ Feature X deshabilitado"
        FAILED_CHECKS+=("Feature X no habilitado")
        return 1
    fi
}
```

Luego llamarla en el loop principal (línea ~250):

```bash
check_feature_x "$vm_values"
```

### Dependencias

- **jq**: Procesador JSON
  ```bash
  apt-get install jq  # Ubuntu/Debian
  brew install jq     # macOS
  ```

### Troubleshooting

#### Error: "jq no está instalado"

```bash
# Instalar jq
sudo apt-get update && sudo apt-get install -y jq
```

#### Error: "Archivo de plan no encontrado"

```bash
# Verificar que tfplan.json existe
ls -la tfplan.json

# Regenerar si es necesario
terraform show -json tfplan > tfplan.json
```

#### No detecta VMs en el plan

```bash
# Verificar que el plan contiene VMs
jq '.resource_changes[]? | select(.type | contains("virtual_machine"))' tfplan.json
```

#### Compliance score inesperado

```bash
# Ejecutar en modo verbose
bash -x ./scripts/security-validator.sh tfplan.json
```

---

## 📥 Azure Resource Importer (`import-azure-resources.sh`)

Script interactivo para importar recursos existentes de Azure a Terraform de manera guiada.

### Características

- ✅ Wizard interactivo paso a paso
- ✅ Descubrimiento automático de recursos en Azure
- ✅ Generación automática de configuración Terraform
- ✅ Generación de comandos `terraform import`
- ✅ Log automático de todas las importaciones
- ✅ Soporte para múltiples tipos de recursos
- ✅ Validación de dependencias

### Tipos de Recursos Soportados

| Recurso | Estado | Generación Automática |
|---------|--------|----------------------|
| **Resource Group** | ✅ Completo | ✅ Si |
| **Virtual Network** | ✅ Completo | ✅ Si |
| **Subnet** | ⚠️  Desarrollo | ⚠️  Parcial |
| **Network Security Group** | ✅ Completo | ✅ Si |
| **Virtual Machine (Linux)** | ⚠️  Desarrollo | ⚠️  Parcial |
| **Virtual Machine (Windows)** | ⚠️  Desarrollo | ⚠️  Parcial |
| **Network Interface** | ⚠️  Desarrollo | ⚠️  Parcial |
| **Managed Disk** | ⚠️  Desarrollo | ⚠️  Parcial |
| **Storage Account** | ✅ Completo | ✅ Si |
| **Key Vault** | ⚠️  Desarrollo | ⚠️  Parcial |
| **Azure SQL** | ⚠️  Desarrollo | ⚠️  Parcial |
| **Container Registry** | ⚠️  Desarrollo | ⚠️  Parcial |

### Uso

#### Ejecución Interactiva

```bash
# Ejecutar el wizard
./scripts/import-azure-resources.sh
```

#### Flujo del Wizard

```
1. Verificación de dependencias (az, terraform, jq)
   ↓
2. Login a Azure (si es necesario)
   ↓
3. Selección de suscripción
   ↓
4. Selección de Resource Group
   ↓
5. Menú de tipo de recurso
   ↓
6. Selección de recurso específico
   ↓
7. Generación de configuración Terraform
   ↓
8. Generación de comando import
   ↓
9. Opción de ejecutar import inmediatamente
   ↓
10. Log automático en archivo .md
```

### Ejemplo de Uso

```bash
$ ./scripts/import-azure-resources.sh

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
   Suscripción: Xpertal Production
   ID: 12345678-1234-1234-1234-123456789012

📦 Seleccionar Resource Group...

Resource Groups disponibles:

  1) rg-production-eastus          [eastus]
  2) rg-development-westus         [westus]
  3) XPERTAL-Shared-xcs-ti-rg      [southcentralus]

Selecciona el número del Resource Group: 1

✅ Resource Group seleccionado: rg-production-eastus

🎯 ¿Qué tipo de recurso deseas importar?

  1) Resource Group
  2) Virtual Network (VNet)
  3) Subnet
  4) Network Security Group (NSG)
  5) Virtual Machine (Linux)
  6) Virtual Machine (Windows)
  7) Network Interface (NIC)
  8) Managed Disk
  9) Storage Account
 10) Key Vault
  ...
  0) Listar todos los recursos del RG
  q) Salir

Selecciona una opción: 2

🌐 Importar Virtual Network

VNets disponibles:
  1) vnet-production
  2) vnet-shared-services

Selecciona el número de VNet: 1

Configuración Terraform sugerida:

# Virtual Network: vnet-production
resource "azurerm_virtual_network" "vnet_production" {
  name                = "vnet-production"
  resource_group_name = "rg-production-eastus"
  location            = "eastus"
  address_space       = ["10.0.0.0/16", "172.16.0.0/16"]

  tags = {
    "environment" = "production"
    "managed-by"  = "terraform"
  }
}

📝 Comando de importación generado:

terraform import azurerm_virtual_network.vnet_production \
  /subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-production-eastus/providers/Microsoft.Network/virtualNetworks/vnet-production

¿Ejecutar importación ahora? (y/n): y

azurerm_virtual_network.vnet_production: Importing from ID "/subscriptions/..."
azurerm_virtual_network.vnet_production: Import prepared!
azurerm_virtual_network.vnet_production: Refreshing state...

Import successful!

✅ VNet importada exitosamente

Presiona Enter para continuar...
```

### Output del Script

El script genera automáticamente un archivo de log:

```bash
$ ls -la
-rw-r--r-- 1 user user  4521 Jan 21 14:30 import-log-20260121-143022.md
```

Contenido del log:

```markdown
# Log de Importación de Recursos Azure

**Fecha:** Mon Jan 21 14:30:22 UTC 2026
**Suscripción:** 12345678-1234-1234-1234-123456789012
**Resource Group:** rg-production-eastus

---

## Virtual Network: vnet-production

**Comando de importación:**
```bash
terraform import azurerm_virtual_network.vnet_production \
  /subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-production-eastus/providers/Microsoft.Network/virtualNetworks/vnet-production
```

**Configuración Terraform:**
```hcl
# Virtual Network: vnet-production
resource "azurerm_virtual_network" "vnet_production" {
  name                = "vnet-production"
  resource_group_name = "rg-production-eastus"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

  tags = {
    "environment" = "production"
  }
}
```

---

## Storage Account: mystorageaccount

...
```

### Dependencias

```bash
# Verificar que estén instaladas
az --version      # Azure CLI
terraform version # Terraform
jq --version      # JSON processor
```

Instalación:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y azure-cli jq

# macOS
brew install azure-cli jq
```

### Workflow Recomendado

1. **Ejecutar el script:**
   ```bash
   ./scripts/import-azure-resources.sh
   ```

2. **Copiar la configuración generada** a `import.tf` o el archivo apropiado

3. **Ejecutar el comando de importación** (o permitir que el script lo haga)

4. **Validar con terraform plan:**
   ```bash
   terraform plan
   ```

5. **Ajustar configuración** hasta que no haya diferencias

6. **Commit del código:**
   ```bash
   git add import.tf
   git commit -m "feat: Import existing Azure resources"
   ```

### Troubleshooting

#### Error: "jq not found"

```bash
# Instalar jq
sudo apt-get install jq  # Ubuntu/Debian
brew install jq          # macOS
```

#### Error: "az: command not found"

```bash
# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### El script no lista recursos

```bash
# Verificar login
az account show

# Verificar permisos
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Limitaciones Actuales

- ⚠️  Algunos recursos complejos (VMs, SQL) requieren ajuste manual
- ⚠️  No importa automáticamente recursos anidados (NSG rules, subnets)
- ⚠️  No detecta dependencias entre recursos

### Roadmap

- [ ] Soporte completo para todos los módulos del repositorio
- [ ] Detección automática de dependencias
- [ ] Importación en lote (múltiples recursos)
- [ ] Integración con módulos existentes
- [ ] Validación automática post-importación

### Guía Completa

Para documentación detallada, ver:
- [Guía Completa de Importación](../docs/IMPORT-GUIDE.md)

---

## 🔄 Otros Scripts

### `generate_ansible_inventory.sh`

> ⚠️ **Pendiente de implementación**

Generará inventario de Ansible basado en el estado de Terraform.

### `run_ansible.sh`

> ⚠️ **Pendiente de implementación**

Ejecutará playbooks de Ansible contra la infraestructura desplegada.

---

## 📋 Mejores Prácticas

1. **Siempre ejecutar security validator** antes de aprobar cambios en producción
2. **No bypass validaciones** para "deployar rápido" - la seguridad es crítica
3. **Revisar failed checks** antes de aprobar, incluso si compliance ≥ 70%
4. **Documentar excepciones** si se aprueba un deployment con warnings
5. **Actualizar thresholds** según madurez del equipo y políticas de seguridad

---

## 🔗 Referencias

- [Terraform JSON Output](https://www.terraform.io/docs/internals/json-format.html)
- [Azure VM Security Best Practices](https://learn.microsoft.com/azure/security/fundamentals/virtual-machines-overview)
- [GitHub Actions Step Summaries](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#adding-a-job-summary)
- [jq Manual](https://stedolan.github.io/jq/manual/)

---

## 📄 Licencia

Este script es parte del repositorio **xpeterraform-azure** de Xpertal.

---

## 👥 Soporte

Para problemas o mejoras, contactar al equipo de infraestructura o crear un issue en GitHub.
