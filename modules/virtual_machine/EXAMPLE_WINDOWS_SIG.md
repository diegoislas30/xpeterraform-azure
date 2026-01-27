# Ejemplo Completo: Windows VM desde Shared Image Gallery (SIG)

**Configuración completa lista para producción con todas las opciones importantes**

## 📋 Código Completo

```hcl
# ============================================================================
# EJEMPLO COMPLETO: Windows VM desde Shared Image Gallery
# ============================================================================

# 1. Network Security Group (NSG) con reglas
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "nsg-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Regla: Permitir RDP desde red interna
  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.0.0/8"  # Ajustar a tu red
    destination_address_prefix = "*"
  }

  # Regla: Permitir WinRM para administración remota
  security_rule {
    name                       = "AllowWinRM"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5985", "5986"]
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }

  tags = {
    UDN      = "IT"
    OWNER    = "AppTeam"
    xpeowner = "app-team@empresa.com"
    proyecto = "aplicaciones"
    ambiente = "produccion"
  }
}

# 2. Route Table (Opcional - solo si necesitas ruteo custom)
resource "azurerm_route_table" "vm_routes" {
  count               = var.enable_custom_routes ? 1 : 0
  name                = "rt-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Ejemplo: Ruta hacia Firewall/NVA
  route {
    name                   = "ToFirewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"  # IP del Firewall
  }

  tags = {
    UDN      = "IT"
    OWNER    = "AppTeam"
    xpeowner = "app-team@empresa.com"
    proyecto = "aplicaciones"
    ambiente = "produccion"
  }
}

# 3. Virtual Machine desde SIG
module "windows_vm_from_sig" {
  source = "./modules/virtual_machine"

  # ============================================================================
  # PARÁMETROS GENERALES
  # ============================================================================
  vm_name             = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location  # Misma región que el resource group

  # ============================================================================
  # SISTEMA OPERATIVO Y TAMAÑO
  # ============================================================================
  os_type = "windows"
  vm_size = "Standard_D4s_v3"  # 4 vCPUs, 16 GB RAM - AJUSTAR según necesidad

  # ============================================================================
  # IMAGEN: Shared Image Gallery (source_image_id)
  # ============================================================================
  use_marketplace_image = false
  source_image_id       = var.source_image_id

  # IMPORTANTE: Con source_image_id NO usar TrustedLaunch
  security_type = "Standard"

  # Si fuera Marketplace, descomentar esto:
  # use_marketplace_image = true
  # marketplace_image = {
  #   publisher = "MicrosoftWindowsServer"
  #   offer     = "WindowsServer"
  #   sku       = "2022-datacenter-azure-edition"
  #   version   = "latest"
  # }
  # security_type = "TrustedLaunch"  # ← Habilitar SOLO para Marketplace

  # ============================================================================
  # CREDENCIALES (desde secretos GitHub)
  # ============================================================================
  admin_username = var.admin_username
  admin_password = var.admin_password  # Viene del secreto VM_PASSWORD en GitHub Actions

  # ============================================================================
  # PARÁMETROS DE RED
  # ============================================================================
  subnet_id = var.subnet_id

  # IP Privada: Dynamic (DHCP) o Static (IP fija)
  private_ip_allocation = var.use_static_ip ? "Static" : "Dynamic"
  private_ip_address    = var.use_static_ip ? var.static_ip_address : null

  # Nota: No hay IP pública (configuración segura por defecto)

  # Accelerated Networking (recomendado para VMs D-series y superiores)
  enable_accelerated_networking = true

  # ============================================================================
  # DISCOS
  # ============================================================================

  # OS Disk
  os_disk_size_gb              = var.os_disk_size_gb
  os_disk_storage_account_type = "Premium_LRS"  # Premium para mejor performance
  os_disk_caching              = "ReadWrite"

  # Data Disks (agregar según necesidad)
  data_disks = var.data_disks

  # ============================================================================
  # SEGURIDAD Y ENCRIPTACIÓN
  # ============================================================================

  # Encriptación en el host (requiere feature habilitado en suscripción)
  encryption_at_host_enabled = var.enable_encryption_at_host

  # Managed Identity para acceso seguro sin credenciales
  identity_type = "SystemAssigned"

  # Azure Hybrid Benefit (ahorro de costos si tienes licencias)
  license_type = var.enable_hybrid_benefit ? "Windows_Server" : null

  # Patch Management automático
  patch_mode            = "AutomaticByPlatform"
  patch_assessment_mode = "AutomaticByPlatform"

  # ============================================================================
  # TAGS
  # ============================================================================
  tags = var.tags
}

# 4. Asociar NSG a la NIC
resource "azurerm_network_interface_security_group_association" "vm_nsg_assoc" {
  network_interface_id      = module.windows_vm_from_sig.nic_id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# 5. Asociar Route Table a la Subnet (Opcional)
resource "azurerm_subnet_route_table_association" "vm_routes_assoc" {
  count          = var.enable_custom_routes ? 1 : 0
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.vm_routes[0].id
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "vm_id" {
  description = "ID de la VM creada"
  value       = module.windows_vm_from_sig.vm_id
}

output "vm_name" {
  description = "Nombre de la VM"
  value       = module.windows_vm_from_sig.vm_name
}

output "private_ip" {
  description = "IP privada asignada"
  value       = module.windows_vm_from_sig.private_ip
}

output "nic_id" {
  description = "ID de la NIC"
  value       = module.windows_vm_from_sig.nic_id
}

output "managed_identity_principal_id" {
  description = "Principal ID de la Managed Identity (para asignar permisos)"
  value       = module.windows_vm_from_sig.principal_id
}

output "nsg_id" {
  description = "ID del Network Security Group"
  value       = azurerm_network_security_group.vm_nsg.id
}
```

---

## 📋 Variables necesarias (variables.tf)

```hcl
# ============================================================================
# PARÁMETROS GENERALES
# ============================================================================

variable "vm_name" {
  description = "Nombre de la VM"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
}

variable "location" {
  description = "Región de Azure (debe coincidir con el resource group)"
  type        = string
}

# ============================================================================
# PARÁMETROS DE RED
# ============================================================================

variable "subnet_id" {
  description = "ID de la subnet donde se desplegará la VM"
  type        = string
}

variable "use_static_ip" {
  description = "Usar IP estática (true) o DHCP (false)"
  type        = bool
  default     = false
}

variable "static_ip_address" {
  description = "IP privada fija (solo si use_static_ip = true)"
  type        = string
  default     = null
}

variable "enable_custom_routes" {
  description = "Habilitar route table custom"
  type        = bool
  default     = false
}

# ============================================================================
# IMAGEN
# ============================================================================

variable "source_image_id" {
  description = "ID completo de la imagen en Shared Image Gallery"
  type        = string
}

# ============================================================================
# CREDENCIALES
# ============================================================================

variable "admin_username" {
  description = "Nombre de usuario administrador"
  type        = string
  default     = "winadmin"
}

variable "admin_password" {
  description = "Password del administrador (viene del secreto VM_PASSWORD en GitHub Actions)"
  type        = string
  sensitive   = true
}

# ============================================================================
# DISCOS
# ============================================================================

variable "os_disk_size_gb" {
  description = "Tamaño del OS Disk en GB"
  type        = number
  default     = 128
}

variable "data_disks" {
  description = "Lista de data disks a crear"
  type = list(object({
    lun                  = number
    size_gb              = number
    caching              = optional(string, "ReadOnly")
    storage_account_type = optional(string, "Premium_LRS")
  }))
  default = []
}

# ============================================================================
# SEGURIDAD
# ============================================================================

variable "enable_encryption_at_host" {
  description = "Habilitar encriptación en el host"
  type        = bool
  default     = false
}

variable "enable_hybrid_benefit" {
  description = "Habilitar Azure Hybrid Benefit (ahorro de costos)"
  type        = bool
  default     = false
}

# ============================================================================
# TAGS
# ============================================================================

variable "tags" {
  description = "Tags para todos los recursos"
  type = object({
    UDN      = string
    OWNER    = string
    xpeowner = string
    proyecto = string
    ambiente = string
  })
}
```

---

## 🎯 Ejemplo de terraform.tfvars

```hcl
# Parámetros generales
vm_name             = "vm-win-app-001"
resource_group_name = "rg-production"
location            = "eastus"

# Red
subnet_id          = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/subnet-vms"
use_static_ip      = true
static_ip_address  = "10.0.1.10"
enable_custom_routes = false  # true si necesitas route table

# Imagen SIG
source_image_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-images/providers/Microsoft.Compute/galleries/myGallery/images/Win2022-Custom/versions/1.0.0"

# Credenciales
admin_username = "winadmin"
# admin_password viene del secreto VM_PASSWORD en GitHub Actions

# Discos
os_disk_size_gb = 128

data_disks = [
  {
    lun                  = 0
    size_gb              = 256
    caching              = "ReadOnly"
    storage_account_type = "Premium_LRS"
  },
  {
    lun                  = 1
    size_gb              = 512
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
]

# Seguridad
enable_encryption_at_host = true
enable_hybrid_benefit     = true

# Tags
tags = {
  UDN      = "IT"
  OWNER    = "AppTeam"
  xpeowner = "app-team@empresa.com"
  proyecto = "aplicaciones"
  ambiente = "produccion"
}
```

---

## 🚀 Guía de Uso

### 1. Obtener el source_image_id de tu SIG

```bash
# Listar todas las imágenes en tu galería
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

### 2. Configurar el secreto VM_PASSWORD en GitHub

1. Ve a tu repositorio en GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Click en **"New repository secret"**
4. **Name:** `VM_PASSWORD`
5. **Secret:** Tu contraseña (mín. 12 chars, mayúsculas, minúsculas, números, símbolos)

### 3. Desplegar

**Localmente:**
```bash
terraform init
terraform plan -var="admin_password=TuPassword123!"
terraform apply -var="admin_password=TuPassword123!"
```

**En GitHub Actions:**
```bash
# El password viene automáticamente del secreto VM_PASSWORD
git add .
git commit -m "feat: Add Windows VM from SIG"
git push
```

---

## ⚙️ Configuraciones Comunes

### Tamaños de VM recomendados

| Tamaño | vCPUs | RAM | Tipo | Uso |
|--------|-------|-----|------|-----|
| `Standard_B2s` | 2 | 4 GB | Burstable | Dev/Test |
| `Standard_D2s_v3` | 2 | 8 GB | General | Apps pequeñas |
| `Standard_D4s_v3` | 4 | 16 GB | General | **Apps medianas (recomendado)** |
| `Standard_D8s_v3` | 8 | 32 GB | General | Apps grandes |
| `Standard_E4s_v3` | 4 | 32 GB | Memory | SQL Server, SAP |
| `Standard_F4s_v2` | 4 | 8 GB | Compute | CPU intensive |

### Configuración de IP

**IP Dinámica (DHCP) - Por defecto:**
```hcl
use_static_ip = false
```

**IP Estática (Fija):**
```hcl
use_static_ip     = true
static_ip_address = "10.0.1.10"  # Debe estar en el rango de la subnet
```

### Reglas NSG comunes

**RDP desde VPN:**
```hcl
source_address_prefix = "192.168.1.0/24"
```

**RDP desde Azure Bastion:**
```hcl
source_address_prefix = "AzureBastionSubnet"
```

**HTTP/HTTPS:**
```hcl
destination_port_ranges = ["80", "443"]
```

**SQL Server:**
```hcl
destination_port_range = "1433"
```

### Configuración de Data Disks

**Sin data disks:**
```hcl
data_disks = []
```

**Un disco:**
```hcl
data_disks = [
  {
    lun                  = 0
    size_gb              = 256
    caching              = "ReadOnly"
    storage_account_type = "Premium_LRS"
  }
]
```

**Múltiples discos:**
```hcl
data_disks = [
  {
    lun                  = 0
    size_gb              = 256
    caching              = "ReadOnly"
    storage_account_type = "Premium_LRS"
  },
  {
    lun                  = 1
    size_gb              = 512
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  },
  {
    lun                  = 2
    size_gb              = 1024
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }
]
```

---

## 🔒 Características de Seguridad

### Implementadas por defecto

✅ **Sin IP pública** - Solo acceso interno desde Azure
✅ **NSG en la NIC** - Firewall a nivel de interfaz de red
✅ **Managed Identity** - Autenticación sin contraseñas para Azure resources
✅ **Password desde secreto** - No expuesto en código ni logs
✅ **Patch Management** - Actualizaciones automáticas de seguridad

### Opcionales (configurables)

⚙️ **Encryption at host** - Datos encriptados en el servidor físico de Azure
⚙️ **TrustedLaunch** - Solo para imágenes Marketplace (vTPM + Secure Boot)
⚙️ **Azure Hybrid Benefit** - Ahorro de costos usando licencias existentes
⚙️ **Route Table** - Ruteo custom a través de Firewall/NVA

---

## 📝 Notas Importantes

### 1. TrustedLaunch vs Standard

- **source_image_id (SIG)** → Usar `security_type = "Standard"`
- **Marketplace images** → Usar `security_type = "TrustedLaunch"`

**Razón:** Las imágenes de SIG pueden no tener el soporte Gen2 necesario para TrustedLaunch.

### 2. Encryption at Host

Requiere habilitar el feature en la suscripción (solo una vez):

```bash
az feature register \
  --namespace Microsoft.Compute \
  --name EncryptionAtHost

# Verificar el estado
az feature show \
  --namespace Microsoft.Compute \
  --name EncryptionAtHost \
  --query properties.state
```

### 3. Route Table

- Se aplica a nivel de **subnet**, no de NIC individual
- Afecta a **todas las VMs** en esa subnet
- Solo agregar si necesitas ruteo custom (ej: hacia Firewall)

### 4. NSG: NIC vs Subnet

Este ejemplo asocia el NSG a la **NIC** (interfaz de red):
- ✅ Permite reglas específicas por VM
- ✅ Más granular y seguro

Alternativa (NSG en subnet):
- Se aplica a todas las VMs en la subnet
- Menos flexible

### 5. Accelerated Networking

- Solo disponible en tamaños **D-series o superiores**
- Mejora significativamente el rendimiento de red
- No disponible en tamaños B-series (burstable)

---

## 🔍 Troubleshooting

### Error: "admin_password is required"

**Causa:** El secreto `VM_PASSWORD` no está configurado en GitHub

**Solución:**
1. Ve a Settings → Secrets and variables → Actions
2. Crea el secreto `VM_PASSWORD`
3. Asegúrate que el workflow incluye `TF_VAR_admin_password: ${{ secrets.VM_PASSWORD }}`

### Error: "Password does not meet complexity requirements"

**Causa:** La contraseña no cumple los requisitos de Azure

**Requisitos:**
- Mínimo 12 caracteres
- Al menos 3 de estos 4:
  - Mayúsculas (A-Z)
  - Minúsculas (a-z)
  - Números (0-9)
  - Símbolos (!@#$%^&*)

### Error: "Encryption at host is not enabled"

**Causa:** El feature no está habilitado en la suscripción

**Solución:**
```bash
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
```

Esperar a que el estado sea "Registered" (puede tomar minutos).

### Error: "Image not found" o "Image not replicated"

**Causa:** La imagen SIG no está en la región correcta

**Solución:**
1. Verificar que la imagen está replicada en la región de la VM:
```bash
az sig image-version show \
  --resource-group rg-images \
  --gallery-name myGallery \
  --gallery-image-definition Win2022-Custom \
  --gallery-image-version 1.0.0 \
  --query "publishingProfile.targetRegions[*].name"
```

2. Replicar si es necesario:
```bash
az sig image-version update \
  --resource-group rg-images \
  --gallery-name myGallery \
  --gallery-image-definition Win2022-Custom \
  --gallery-image-version 1.0.0 \
  --target-regions "eastus=1" "westus=1"
```

---

## 📚 Referencias

- [Azure VM Sizes](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes)
- [Shared Image Gallery](https://learn.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries)
- [Trusted Launch](https://learn.microsoft.com/en-us/azure/virtual-machines/trusted-launch)
- [Azure Hybrid Benefit](https://azure.microsoft.com/en-us/pricing/hybrid-benefit/)
