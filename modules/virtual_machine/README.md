# Módulo Terraform: Azure Virtual Machine

Módulo completo y seguro para desplegar **máquinas virtuales de Azure** con soporte para:
- Imágenes **SIG/Managed Images** o **Azure Marketplace**
- **SSH keys** para Linux (seguro por defecto)
- **Managed Identity** (System y User Assigned)
- **Trusted Launch** y **encryption-at-host**
- **Cloud-init** y scripts personalizados
- **Azure Monitor Agent** y extensiones
- **Azure Hybrid Benefit**
- **Data disks** gestionados

---

## 🔒 Características de Seguridad

### ✅ Implementadas por defecto
- Sin IP pública en la NIC
- SSH keys requeridas para Linux (contraseñas deshabilitadas)
- Trusted Launch habilitado (vTPM + Secure Boot)
- Soporte para encryption-at-host
- Managed Identity para autenticación sin credenciales

### ⚙️ Configurables
- Azure Hybrid Benefit
- Patch management automático
- Azure Monitor Agent
- Accelerated Networking

---

## 📋 Requisitos

- Provider `azurerm` ≥ **3.116**
- Permisos para crear VMs, NICs y Discos
- Para imágenes SIG cross-subscription: Role **Reader** en la galería
- Para encryption-at-host: Feature habilitado en la suscripción
  ```bash
  az feature register --namespace Microsoft.Compute --name EncryptionAtHost
  ```

---

## 🚀 Uso Rápido

### Ejemplo 1: Linux VM con SSH keys (Marketplace)

```hcl
module "linux_vm" {
  source = "./modules/virtual_machine"

  vm_name             = "vm-ubuntu-web-01"
  resource_group_name = "rg-production"
  location            = "eastus"
  subnet_id           = "/subscriptions/.../subnets/web-subnet"

  os_type = "linux"
  vm_size = "Standard_D2s_v3"

  # Imagen de Marketplace (Ubuntu 22.04)
  use_marketplace_image = true
  marketplace_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Autenticación SSH (segura)
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_keys = [
    {
      username   = "azureuser"
      public_key = file("~/.ssh/id_rsa.pub")
    }
  ]

  # Managed Identity para acceso a Key Vault
  identity_type = "SystemAssigned"

  # Seguridad mejorada
  encryption_at_host_enabled = true

  tags = {
    UDN      = "IT"
    OWNER    = "DevOps"
    xpeowner = "admin@empresa.com"
    proyecto = "webapp"
    ambiente = "produccion"
  }
}
```

### Ejemplo 2: Windows Server con Managed Identity

```hcl
module "windows_vm" {
  source = "./modules/virtual_machine"

  vm_name             = "vm-winserver-01"
  resource_group_name = "rg-production"
  location            = "eastus"
  subnet_id           = "/subscriptions/.../subnets/app-subnet"

  os_type = "windows"
  vm_size = "Standard_D4s_v3"

  # Imagen de Marketplace
  use_marketplace_image = true
  marketplace_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  admin_username = "adminuser"
  admin_password = var.admin_password # Desde variable segura

  # Managed Identity
  identity_type = "SystemAssigned"

  # Azure Hybrid Benefit (ahorro de costos)
  license_type = "Windows_Server"

  # Patch management automático
  patch_mode            = "AutomaticByPlatform"
  patch_assessment_mode = "AutomaticByPlatform"

  # Data disks
  data_disks = [
    {
      lun                  = 0
      size_gb              = 512
      storage_account_type = "Premium_LRS"
      caching              = "ReadWrite"
    }
  ]

  tags = {
    UDN      = "IT"
    OWNER    = "AppTeam"
    xpeowner = "admin@empresa.com"
    proyecto = "erp"
    ambiente = "produccion"
  }
}
```

### Ejemplo 3: Linux con Cloud-init y Monitoring

```hcl
module "linux_vm_monitored" {
  source = "./modules/virtual_machine"

  vm_name             = "vm-app-monitored"
  resource_group_name = "rg-production"
  location            = "eastus"
  subnet_id           = var.subnet_id

  os_type = "linux"
  vm_size = "Standard_B2ms"

  use_marketplace_image = true
  marketplace_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username = "azureuser"
  admin_ssh_keys = [
    {
      username   = "azureuser"
      public_key = file("~/.ssh/id_rsa.pub")
    }
  ]

  # Cloud-init para configuración inicial
  user_data = <<-EOT
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - nginx
      - docker.io
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
      - usermod -aG docker azureuser
  EOT

  # Azure Monitor Agent
  enable_azure_monitor_agent   = true
  log_analytics_workspace_id   = var.workspace_id
  log_analytics_workspace_key  = var.workspace_key

  # Managed Identity
  identity_type = "SystemAssigned"

  tags = {
    UDN      = "IT"
    OWNER    = "DevOps"
    xpeowner = "devops@empresa.com"
    proyecto = "microservices"
    ambiente = "dev"
  }
}
```

### Ejemplo 4: VM desde Shared Image Gallery (SIG)

```hcl
module "vm_from_sig" {
  source = "./modules/virtual_machine"

  vm_name             = "vm-custom-image"
  resource_group_name = "rg-production"
  location            = "eastus"
  subnet_id           = var.subnet_id

  os_type = "linux"
  vm_size = "Standard_D2s_v3"

  # Imagen personalizada desde SIG
  use_marketplace_image = false
  source_image_id       = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Compute/galleries/<gallery>/images/<image>/versions/1.0.0"

  admin_username = "azureuser"
  admin_ssh_keys = [
    {
      username   = "azureuser"
      public_key = file("~/.ssh/id_rsa.pub")
    }
  ]

  # Trusted Launch (si la imagen es Gen2)
  security_type = "TrustedLaunch"

  tags = {
    UDN      = "IT"
    OWNER    = "Platform"
    xpeowner = "platform@empresa.com"
    proyecto = "golden-images"
    ambiente = "produccion"
  }
}
```

### Ejemplo 5: Custom Script Extension

```hcl
module "vm_with_script" {
  source = "./modules/virtual_machine"

  vm_name             = "vm-with-script"
  resource_group_name = "rg-test"
  location            = "eastus"
  subnet_id           = var.subnet_id

  os_type = "linux"
  vm_size = "Standard_B1s"

  use_marketplace_image = true
  marketplace_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username = "azureuser"
  admin_ssh_keys = [
    {
      username   = "azureuser"
      public_key = file("~/.ssh/id_rsa.pub")
    }
  ]

  # Custom Script Extension
  custom_script_extension = {
    file_uris = [
      "https://mystorageaccount.blob.core.windows.net/scripts/setup.sh"
    ]
    command_to_execute   = "bash setup.sh"
    storage_account_name = "mystorageaccount"
    storage_account_key  = var.storage_key
  }

  identity_type = "SystemAssigned"

  tags = {
    UDN      = "IT"
    OWNER    = "DevOps"
    xpeowner = "test@empresa.com"
    proyecto = "automation"
    ambiente = "test"
  }
}
```

### Ejemplo 6: Windows Server desde Shared Image Gallery (SIG)

```hcl
module "windows_vm_from_sig" {
  source = "./modules/virtual_machine"

  vm_name             = "vm-win-custom-001"
  resource_group_name = "rg-production"
  location            = "eastus"
  subnet_id           = var.subnet_id

  # Windows Server
  os_type = "windows"
  vm_size = "Standard_D4s_v3"

  # Imagen personalizada desde Shared Image Gallery
  use_marketplace_image = false
  source_image_id       = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-images/providers/Microsoft.Compute/galleries/myGallery/images/WindowsServer2022-Custom/versions/1.0.0"

  # Autenticación Windows (contraseña requerida)
  admin_username = "winadmin"
  admin_password = var.windows_admin_password  # Debe ser sensitive y estar en Key Vault

  # Seguridad máxima
  security_type       = "TrustedLaunch"
  secure_boot_enabled = true
  vtpm_enabled        = true
  encryption_at_host  = true

  # Azure Hybrid Benefit (ahorro de costos si tienes licencias)
  hybrid_benefit = true

  # Managed Identity para acceso a Azure Key Vault sin contraseñas
  identity_type = "SystemAssigned"

  # Discos adicionales para aplicaciones
  data_disks = [
    {
      name                 = "datadisk01"
      disk_size_gb         = 128
      storage_account_type = "Premium_LRS"
      caching              = "ReadWrite"
    },
    {
      name                 = "datadisk02"
      disk_size_gb         = 256
      storage_account_type = "Premium_LRS"
      caching              = "ReadOnly"
    }
  ]

  # Configuración de red
  enable_accelerated_networking = true
  private_ip_address            = "10.0.1.100"

  # Custom Script Extension para Windows (configuración post-instalación)
  custom_script_extension = {
    file_uris = [
      "https://mystorageaccount.blob.core.windows.net/scripts/Configure-WindowsServer.ps1"
    ]
    command_to_execute   = "powershell -ExecutionPolicy Unrestricted -File Configure-WindowsServer.ps1"
    storage_account_name = "mystorageaccount"
    storage_account_key  = var.storage_account_key
  }

  # User data para configuración inicial (codificado en base64 automáticamente)
  user_data = <<-EOF
    #ps1_sysnative
    # Script de inicialización de Windows
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    Set-TimeZone -Id "Eastern Standard Time"
    New-Item -Path "C:\Apps" -ItemType Directory -Force

    # Configurar Windows Defender
    Set-MpPreference -DisableRealtimeMonitoring $false
    Update-MpSignature
  EOF

  tags = {
    UDN      = "IT"
    OWNER    = "Infrastructure"
    xpeowner = "infra@empresa.com"
    proyecto = "active-directory"
    ambiente = "produccion"
    os       = "windows"
    backup   = "daily"
  }
}

# Ejemplo de configuración de secrets en Key Vault (recomendado)
data "azurerm_key_vault_secret" "windows_admin_pwd" {
  name         = "windows-admin-password"
  key_vault_id = var.key_vault_id
}

variable "windows_admin_password" {
  description = "Contraseña del administrador Windows"
  type        = string
  sensitive   = true
  default     = null

  # Si no se proporciona, usar Key Vault
  validation {
    condition     = var.windows_admin_password != null || data.azurerm_key_vault_secret.windows_admin_pwd.value != null
    error_message = "Debe proporcionar admin_password o configurar Key Vault."
  }
}
```

**Notas importantes para Windows VMs desde SIG:**

1. **Imagen personalizada**: El `source_image_id` debe apuntar a una versión específica en tu Shared Image Gallery
2. **Generación de imagen**: Si la imagen es Gen2, puedes usar `security_type = "TrustedLaunch"` con vTPM y Secure Boot
3. **Contraseña obligatoria**: Windows requiere `admin_password` (diferente a Linux con SSH keys)
4. **Complejidad de contraseña**: Debe cumplir requisitos de Azure (12+ caracteres, mayúsculas, minúsculas, números, símbolos)
5. **Azure Hybrid Benefit**: Activa `hybrid_benefit = true` si tu imagen personalizada tiene licencias Windows Server/SQL Server
6. **Custom Script Extension**: Usa PowerShell para configuración post-despliegue
7. **User data**: Para Windows usa formato `#ps1_sysnative` o `#ps1` al inicio del script
8. **Sysprep**: Asegúrate de que tu imagen personalizada fue generalizada con `sysprep` antes de capturarla
9. **Ubicación**: La VM debe estar en la misma región que la Shared Image Gallery (o usar replicación de imágenes)

---

## 📥 Variables de Entrada

### ⚡ Obligatorias

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `vm_name` | string | Nombre único de la VM |
| `resource_group_name` | string | Resource Group de Azure |
| `location` | string | Región de Azure (ej. eastus) |
| `subnet_id` | string | ID de la subnet (sin IP pública) |
| `os_type` | string | Sistema operativo: `linux` o `windows` |
| `tags` | object | Tags obligatorios: UDN, OWNER, xpeowner, proyecto, ambiente |

### 🖼️ Fuente de Imagen (elegir una)

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `use_marketplace_image` | bool | `false` | Usar imagen de Marketplace |
| `marketplace_image` | object | `null` | `{ publisher, offer, sku, version }` |
| `source_image_id` | string | `null` | ID ARM de SIG o Managed Image |
| `marketplace_plan` | object | `null` | Plan para imágenes de terceros |

### 🔐 Autenticación

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `admin_username` | string | `"spyderadmin"` | Usuario administrador |
| `admin_password` | string (sensitive) | `null` | Contraseña (requerida para Windows) |
| `disable_password_authentication` | bool | `true` | Deshabilitar contraseñas en Linux |
| `admin_ssh_keys` | list(object) | `[]` | SSH public keys para Linux |

### 🎯 Configuración de VM

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `vm_size` | string | `"Standard_B1s"` | Tamaño de la VM |
| `zone` | string | `null` | Availability Zone (1, 2, 3) |
| `security_type` | string | `"TrustedLaunch"` | TrustedLaunch o Standard |

### 💾 Discos

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `os_disk_size_gb` | number | `128` | Tamaño del OS disk en GB |
| `os_disk_storage_account_type` | string | `"StandardSSD_LRS"` | SKU del OS disk |
| `os_disk_caching` | string | `null` → ReadWrite | Caching del OS disk |
| `data_disks` | list(object) | `[]` | Lista de data disks (ver ejemplo) |

### 🌐 Redes

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `enable_accelerated_networking` | bool | `false` | Accelerated Networking |
| `private_ip_allocation` | string | `"Dynamic"` | Dynamic o Static |
| `private_ip_address` | string | `null` | IP privada (si Static) |
| `private_ip_version` | string | `"IPv4"` | IPv4 o IPv6 |

### 🔑 Managed Identity

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `identity_type` | string | `null` | SystemAssigned, UserAssigned o ambos |
| `identity_ids` | list(string) | `[]` | IDs de User Assigned Identities |

### 🛡️ Seguridad Avanzada

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `encryption_at_host_enabled` | bool | `false` | Cifrado en el host (requiere feature) |
| `patch_mode` | string | `null` | Modo de parcheo automático |
| `patch_assessment_mode` | string | `null` | Evaluación de parches |
| `license_type` | string | `null` | Azure Hybrid Benefit |

### 📦 Extensiones

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `enable_azure_monitor_agent` | bool | `false` | Instalar Azure Monitor Agent |
| `log_analytics_workspace_id` | string | `null` | ID del workspace (si AMA=true) |
| `log_analytics_workspace_key` | string (sensitive) | `null` | Key del workspace |
| `custom_script_extension` | object | `null` | Custom Script Extension config |

### ☁️ Inicialización

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `custom_data` | string (sensitive) | `null` | Script base64 para cloud-init/custom script |
| `user_data` | string (sensitive) | `null` | Cloud-init user data (Linux) |

### 🎛️ Otras Configuraciones

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `proximity_placement_group_id` | string | `null` | PPG para baja latencia |
| `availability_set_id` | string | `null` | Availability Set ID |
| `dedicated_host_id` | string | `null` | Dedicated Host ID |
| `additional_capabilities_ultra_ssd_enabled` | bool | `false` | Soporte para Ultra SSD |
| `boot_diagnostics_storage_uri` | string | `null` | Storage para boot diagnostics |

---

## 📤 Outputs

| Output | Descripción |
|--------|-------------|
| `vm_id` | ID de la VM creada |
| `vm_name` | Nombre de la VM |
| `vm_size` | Tamaño de la VM |
| `os_type` | Tipo de sistema operativo |
| `location` | Ubicación de la VM |
| `resource_group_name` | Resource Group |
| `nic_id` | ID de la NIC principal |
| `private_ip` | IP privada asignada |
| `principal_id` | Principal ID de System Managed Identity |
| `identity` | Objeto completo de identity |
| `data_disk_ids` | Mapa de LUN → ID de data disks |
| `os_disk_id` | ID del OS disk |

---

## 🎓 Guía de Buenas Prácticas

### 1. Seguridad

```hcl
# ✅ BUENO: SSH keys para Linux
admin_ssh_keys = [
  {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
]
disable_password_authentication = true

# ❌ MALO: Contraseñas en Linux
disable_password_authentication = false
admin_password = "Password123!"
```

### 2. Managed Identity

```hcl
# ✅ BUENO: System Assigned Identity
identity_type = "SystemAssigned"

# Luego dar permisos RBAC
resource "azurerm_role_assignment" "vm_to_keyvault" {
  scope                = azurerm_key_vault.example.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.vm.principal_id
}
```

### 3. Encryption-at-host

```hcl
# Primero registrar el feature
# az feature register --namespace Microsoft.Compute --name EncryptionAtHost
# az provider register --namespace Microsoft.Compute

encryption_at_host_enabled = true
```

### 4. Azure Hybrid Benefit

```hcl
# Ahorro de hasta 40% en costos de licencias Windows/Linux
license_type = "Windows_Server"  # Windows
license_type = "RHEL_BYOS"       # Red Hat Enterprise Linux
license_type = "SLES_BYOS"       # SUSE Linux Enterprise
```

### 5. Data Disks

```hcl
data_disks = [
  {
    lun                  = 0
    size_gb              = 1024
    storage_account_type = "Premium_LRS"
    caching              = "ReadOnly"  # Para datos
  },
  {
    lun                  = 1
    size_gb              = 512
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite" # Para logs
  }
]
```

---

## 🔧 Troubleshooting

### Error: "disable_password_authentication=true pero no hay SSH keys"

```
Solución: Agregar al menos una SSH key en admin_ssh_keys o cambiar disable_password_authentication = false
```

### Error: "source_image_id y marketplace_image son null"

```
Solución: Debes configurar UNA de las dos opciones:
- use_marketplace_image = true + marketplace_image = {...}
- use_marketplace_image = false + source_image_id = "..."
```

### Error: "encryption_at_host not enabled"

```bash
# Registrar el feature primero
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
az feature show --namespace Microsoft.Compute --name EncryptionAtHost
az provider register --namespace Microsoft.Compute
```

### Error: "VM size doesn't support accelerated networking"

```
Solución: enable_accelerated_networking solo funciona con ciertos tamaños de VM.
Consultar: https://learn.microsoft.com/azure/virtual-network/create-vm-accelerated-networking
```

---

## 📊 Matriz de Compatibilidad

| Feature | Linux | Windows | Notas |
|---------|-------|---------|-------|
| SSH Keys | ✅ | ❌ | Solo Linux |
| Managed Identity | ✅ | ✅ | Ambos |
| Trusted Launch | ✅ | ✅ | Requiere imagen Gen2 |
| Encryption-at-host | ✅ | ✅ | Requiere feature habilitado |
| Azure Hybrid Benefit | ✅ (RHEL/SLES) | ✅ (Server/Client) | Licencias BYOS |
| Cloud-init (user_data) | ✅ | ❌ | Solo Linux |
| Custom Script Extension | ✅ | ✅ | Ambos |
| Azure Monitor Agent | ✅ | ✅ | Ambos |
| Marketplace Images | ✅ | ✅ | Ambos |
| SIG/Managed Images | ✅ | ✅ | Ambos |

---

## 🔄 Changelog

### v2.0.0 (2026-01-13) - MAJOR UPDATE

#### ✅ Vulnerabilidades Corregidas
- **CRÍTICO**: Fixed Accelerated Networking no aplicándose a la NIC
- **CRÍTICO**: Implementado soporte para SSH keys en Linux (seguro por defecto)
- **ALTA**: Agregado Managed Identity (System y User Assigned)

#### 🚀 Nuevas Funcionalidades
- Soporte para imágenes de Azure Marketplace
- Custom data / user data para cloud-init
- Extensiones: Azure Monitor Agent, Custom Script Extension
- Encryption-at-host para mayor seguridad
- Azure Hybrid Benefit (license_type)
- Patch management automático
- Proximity Placement Groups
- Availability Sets
- Dedicated Hosts
- Ultra SSD support
- Múltiples outputs mejorados

#### 📖 Mejoras de Documentación
- README completamente reescrito con ejemplos completos
- Matriz de compatibilidad
- Guía de buenas prácticas
- Troubleshooting detallado

#### ⚠️ Breaking Changes
- `admin_password` ahora es opcional (default: null) para Linux con SSH keys
- `disable_password_authentication` ahora default `true` (antes era `false`)
- Validación agregada: Linux requiere SSH keys O password
- `source_image_id` ahora es opcional (antes requerida)
- Se requiere especificar fuente de imagen (Marketplace O custom ID)

---

## 📚 Referencias

- [Azure Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/)
- [Trusted Launch](https://learn.microsoft.com/azure/virtual-machines/trusted-launch)
- [Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Azure Hybrid Benefit](https://azure.microsoft.com/pricing/hybrid-benefit/)
- [Cloud-init](https://learn.microsoft.com/azure/virtual-machines/linux/using-cloud-init)

---

## 📄 Licencia

Este módulo es parte del repositorio **xpeterraform-azure** de Xpertal.

---

## 👥 Contribución

Para reportar problemas o sugerir mejoras, contactar al equipo de infraestructura.
