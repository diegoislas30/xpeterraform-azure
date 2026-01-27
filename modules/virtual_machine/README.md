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

### Ejemplo 6: Windows VM desde Shared Image Gallery (SIG)

**Configuración mínima y directa para despliegue rápido**

```hcl
module "windows_vm_from_sig" {
  source = "./modules/virtual_machine"

  # Configuración básica
  vm_name             = "vm-win-app-001"
  resource_group_name = "rg-production"
  location            = "eastus"
  subnet_id           = "/subscriptions/xxx/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/subnet-vms"

  # Windows Server
  os_type = "windows"
  vm_size = "Standard_D2s_v3"

  # Imagen desde Shared Image Gallery (SIG)
  use_marketplace_image = false
  source_image_id       = "/subscriptions/xxx/resourceGroups/rg-images/providers/Microsoft.Compute/galleries/myGallery/images/Win2022-Custom/versions/1.0.0"

  # Credenciales (password viene del secreto VM_PASSWORD en GitHub Actions)
  admin_username = "winadmin"
  admin_password = var.admin_password

  # Tags
  tags = {
    UDN      = "IT"
    OWNER    = "AppTeam"
    xpeowner = "app-team@empresa.com"
    proyecto = "aplicaciones"
    ambiente = "produccion"
  }
}

# Outputs útiles
output "vm_id" {
  value = module.windows_vm_from_sig.vm_id
}

output "private_ip" {
  value = module.windows_vm_from_sig.private_ip_address
}
```

**Cómo obtener el `source_image_id`:**

```bash
# Listar imágenes en tu Shared Image Gallery
az sig image-definition list \
  --resource-group rg-images \
  --gallery-name myGallery \
  --output table

# Obtener el ID completo de una versión específica
az sig image-version show \
  --resource-group rg-images \
  --gallery-name myGallery \
  --gallery-image-definition Win2022-Custom \
  --gallery-image-version 1.0.0 \
  --query id -o tsv
```

**Para usar con GitHub Actions:**
- El password se obtiene automáticamente del secreto `VM_PASSWORD`
- No necesitas configurar nada adicional
- Solo asegúrate de tener el secreto `VM_PASSWORD` en GitHub

### 🔧 Opción alternativa: GitHub Secrets (para GitHub Actions)

Si usas GitHub Actions, almacena las credenciales como secretos del repositorio:

**1. Agregar secretos en GitHub:**
- Ve a: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`
- Agrega: `WIN_ADMIN_USERNAME` = `winadmin`
- Agrega: `WIN_ADMIN_PASSWORD` = `P@ssw0rd123!Complex`
- Agrega: `KEY_VAULT_ID` = `/subscriptions/.../mi-keyvault`

**2. Usar en el workflow `.github/workflows/iac.yml`:**

```yaml
- name: Terraform Plan
  env:
    TF_VAR_key_vault_id: ${{ secrets.KEY_VAULT_ID }}
  run: terraform plan
```

**Las credenciales se obtienen de Key Vault automáticamente, no de GitHub Secrets.**

**Notas importantes:**

| Aspecto | Imagen SIG | Imagen Marketplace |
|---------|------------|-------------------|
| **Trusted Launch** | ⚠️ Solo si la imagen fue creada con Gen2 + TrustedLaunch | ✅ Compatible (usar `use_trusted_launch = true`) |
| **Preparación** | Debe estar generalizada con `sysprep` | Lista para usar |
| **Región** | Debe estar en la misma región o replicada | Disponible en todas las regiones |
| **Recomendación** | `use_trusted_launch = false` (por defecto) | `use_trusted_launch = true` (más segura) |

**🔒 Seguridad de credenciales:**

✅ **CORRECTO (Azure Key Vault):**
- Credenciales almacenadas en Key Vault
- Terraform las obtiene en runtime con `data.azurerm_key_vault_secret`
- NO aparecen en código, logs ni estado de Terraform (están encriptadas)
- Rotación centralizada de contraseñas
- Auditoría completa de accesos

❌ **INCORRECTO (hardcoded):**
- `admin_password = "P@ssw0rd123"` en el código
- `admin_password = var.win_password` con valor en `.tfvars` (se almacena en Git)
- Variables de entorno sin encriptar

**Contraseña:** Debe tener mínimo 12 caracteres con mayúsculas, minúsculas, números y símbolos

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
