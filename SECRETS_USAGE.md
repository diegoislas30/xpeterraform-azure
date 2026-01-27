# 🔐 Uso de Secretos en GitHub Actions

Este documento explica cómo usar los secretos configurados en GitHub Actions con Terraform.

## Secretos Configurados

### Autenticación Azure
| Secreto | Descripción | Uso |
|---------|-------------|-----|
| `AZURE_TENANT_ID` | Tenant ID de Azure | Autenticación con Azure |
| `AZURE_CLIENT_ID` | Client ID del Service Principal | Autenticación con Azure |
| `AZURE_CLIENT_SECRET` | Client Secret del Service Principal | Autenticación con Azure |
| `ARM_ACCESS_KEY` | Access Key del Storage Account | Acceso al backend remoto (tfstate) |

### Credenciales de Recursos
| Secreto | Descripción | Uso |
|---------|-------------|-----|
| `VM_PASSWORD` | Contraseña para VMs Windows/Linux | Creación de máquinas virtuales |

## Cómo se usan los secretos

### 1. En los Workflows de GitHub Actions

Los secretos se definen como variables de entorno en la sección `env:`:

```yaml
env:
  TF_IN_AUTOMATION: true
  ARM_TENANT_ID:     ${{ secrets.AZURE_TENANT_ID }}
  ARM_CLIENT_ID:     ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_ACCESS_KEY:    ${{ secrets.ARM_ACCESS_KEY }}
  TF_VAR_admin_password: ${{ secrets.VM_PASSWORD }}
```

### 2. En el código Terraform

#### Opción A: Variable de entorno (Recomendado para CI/CD)

Cuando defines `TF_VAR_admin_password` en el workflow, Terraform automáticamente usa ese valor para la variable `admin_password`.

**En tu `variables.tf`:**
```hcl
variable "admin_password" {
  description = "Administrator password for the VM"
  type        = string
  sensitive   = true
}
```

**En tu módulo de VM:**
```hcl
module "windows_vm" {
  source = "./modules/virtual_machine"

  vm_name             = "my-windows-vm"
  resource_group_name = "mi-grupo"
  location            = "eastus"

  os_type        = "windows"
  admin_username = "azureadmin"
  admin_password = var.admin_password  # ← Usa la variable

  # ... resto de configuración
}
```

#### Opción B: Pasar explícitamente en terraform plan/apply

```bash
terraform plan -var="admin_password=$VM_PASSWORD"
terraform apply -var="admin_password=$VM_PASSWORD"
```

## Ejemplo Completo: Crear una VM Windows

### 1. En GitHub: Agregar el secreto `VM_PASSWORD`
- Settings → Secrets and variables → Actions
- New repository secret
- Name: `VM_PASSWORD`
- Value: Tu contraseña segura (mín. 12 caracteres, mayúsculas, minúsculas, números, símbolos)

### 2. En tu código Terraform (`main.tf`):

```hcl
module "windows_vm" {
  source = "./modules/virtual_machine"

  vm_name             = "vm-windows-prod-01"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = azurerm_subnet.main.id

  os_type = "windows"
  vm_size = "Standard_B2s"

  # Usar imagen de Marketplace
  use_marketplace_image = true
  marketplace_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  # Credenciales - La password viene del secreto
  admin_username = "azureadmin"
  admin_password = var.admin_password  # ← Automáticamente usa VM_PASSWORD del workflow

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### 3. El workflow automáticamente inyecta la password

Gracias a esta línea en el workflow:
```yaml
TF_VAR_admin_password: ${{ secrets.VM_PASSWORD }}
```

Terraform recibe la password de forma segura sin exponerla en los logs.

## Requisitos de Contraseña para Azure

La contraseña debe cumplir con los siguientes requisitos:

- **Longitud:** Entre 12 y 123 caracteres
- **Complejidad:** Debe contener 3 de los siguientes:
  - Letras minúsculas (a-z)
  - Letras mayúsculas (A-Z)
  - Números (0-9)
  - Símbolos (!@#$%^&*()_+-=[]{}|;:,.<>?)

**Ejemplos de contraseñas válidas:**
- `MySecureP@ssw0rd2024`
- `Azur3-V1rtual-M@chine!`
- `C0mpl3x&Secure#Pass`

## Buenas Prácticas

✅ **Hacer:**
- Usar secretos de GitHub para passwords
- Marcar variables como `sensitive = true` en Terraform
- Rotar las passwords regularmente
- Usar contraseñas diferentes para cada ambiente (dev, staging, prod)

❌ **NO Hacer:**
- Hardcodear passwords en el código
- Commitear archivos `.tfvars` con passwords
- Exponer passwords en logs o outputs
- Compartir passwords por canales inseguros

## Verificar que funciona

Después de configurar el secreto, el workflow:
1. ✅ Lee el secreto `VM_PASSWORD` de GitHub
2. ✅ Lo inyecta como variable de entorno `TF_VAR_admin_password`
3. ✅ Terraform lo usa automáticamente para `var.admin_password`
4. ✅ La VM se crea con esa password (sin exponerla en logs)

## Troubleshooting

### Error: "admin_password is required"
- Verifica que el secreto `VM_PASSWORD` esté configurado en GitHub
- Confirma que el workflow incluye `TF_VAR_admin_password: ${{ secrets.VM_PASSWORD }}`

### Error: "Password does not meet complexity requirements"
- La contraseña debe tener al menos 12 caracteres
- Debe incluir mayúsculas, minúsculas, números y símbolos

### La password no se aplica
- Verifica que tu módulo use `var.admin_password`
- Revisa que el workflow tenga la variable de entorno correcta
