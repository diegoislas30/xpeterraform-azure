variable "vm_name" {
  description = "Nombre de la máquina virtual (único dentro del RG)."
  type        = string
}

variable "computer_name" {
  description = "Nombre del equipo (hostname). Máximo 15 caracteres para Windows. Si no se especifica, usa vm_name."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Nombre del Resource Group."
  type        = string
}

variable "location" {
  description = "Región de Azure (ej. southcentralus)."
  type        = string
}

variable "subnet_id" {
  description = "ID de la Subnet donde nacerá la NIC (sin IP pública)."
  type        = string
}

variable "os_type" {
  description = "Tipo de SO: 'linux' o 'windows'."
  type        = string
  validation {
    condition     = contains(["linux", "windows"], lower(var.os_type))
    error_message = "os_type debe ser 'linux' o 'windows'."
  }
}

variable "vm_size" {
  description = "Tamaño de la VM. Default: el más pequeño recomendado."
  type        = string
  default     = "Standard_B1s"
}

variable "zone" {
  description = "Availability Zone (1,2,3). Dejar null para no usar AZ."
  type        = string
  default     = null
}

variable "security_type" {
  description = "Tipo de seguridad: TrustedLaunch (default) o Standard."
  type        = string
  default     = "TrustedLaunch"
  validation {
    condition     = contains(["trustedlaunch", "standard"], lower(var.security_type))
    error_message = "security_type debe ser 'TrustedLaunch' o 'Standard'."
  }
}

# Imagen por ID ARM (SIG: debe ser la VERSIÓN; Managed Image también soportado)
variable "source_image_id" {
  description = "ID ARM de la imagen. Para SIG debe terminar en /versions/<x.y.z> y estar replicada en la región de la VM; el SP debe tener permiso de lectura."
  type        = string
}

variable "admin_username" {
  description = "Usuario administrador."
  type        = string
  default     = "spyderadmin"
}

variable "admin_password" {
  description = "Contraseña administrador (cumplir complejidad de Azure). Requerida para Windows o si disable_password_authentication = false en Linux."
  type        = string
  sensitive   = true
  default     = null
}

# ===================== LINUX SSH KEYS =====================

variable "disable_password_authentication" {
  description = "Deshabilitar autenticación por contraseña en Linux (recomendado usar SSH keys). Solo aplica a Linux VMs."
  type        = bool
  default     = true
}

variable "admin_ssh_keys" {
  description = "Lista de SSH public keys para Linux VMs. Cada objeto debe tener { username, public_key }. Solo aplica si os_type = 'linux'."
  type = list(object({
    username   = string
    public_key = string
  }))
  default = []
  validation {
    condition     = length(var.admin_ssh_keys) > 0 || var.disable_password_authentication == false
    error_message = "Debes proporcionar al menos una SSH key en admin_ssh_keys si disable_password_authentication = true."
  }
}

# Disco del sistema (OS Disk)
variable "os_disk_size_gb" {
  description = "Tamaño del OS Disk en GB. Default 128 GB."
  type        = number
  default     = 128
}

variable "os_disk_storage_account_type" {
  description = "SKU del OS Disk: StandardSSD_LRS (default), Premium_LRS, etc."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_caching" {
  description = "Caching del OS Disk: None, ReadOnly, ReadWrite. Default ReadWrite."
  type        = string
  default     = null
}

# Data Disks
variable "data_disks" {
  description = <<EOT
Lista de data disks a adjuntar. Cada objeto:
{
  lun                  = number     # requerido (0..63, no repetir)
  size_gb              = number     # requerido
  caching              = optional(string, "ReadOnly")  # None | ReadOnly | ReadWrite
  storage_account_type = optional(string, "StandardSSD_LRS")
}
EOT
  type = list(object({
    lun                  = number
    size_gb              = number
    caching              = optional(string)
    storage_account_type = optional(string)
  }))
  default = []
}

# ===================== MANAGED IDENTITY =====================

variable "identity_type" {
  description = "Tipo de identidad: 'SystemAssigned', 'UserAssigned' o 'SystemAssigned, UserAssigned'. Null para no usar identidad."
  type        = string
  default     = null
  validation {
    condition = var.identity_type == null || contains([
      "systemassigned",
      "userassigned",
      "systemassigned, userassigned"
    ], lower(var.identity_type))
    error_message = "identity_type debe ser 'SystemAssigned', 'UserAssigned', 'SystemAssigned, UserAssigned' o null."
  }
}

variable "identity_ids" {
  description = "Lista de IDs de User Assigned Identities. Requerido si identity_type incluye 'UserAssigned'."
  type        = list(string)
  default     = []
}

# ===================== MARKETPLACE IMAGES =====================

variable "use_marketplace_image" {
  description = "Si true, usa source_image_reference en lugar de source_image_id para imágenes públicas de Marketplace."
  type        = bool
  default     = false
}

variable "marketplace_image" {
  description = "Configuración de imagen de Marketplace. Solo se usa si use_marketplace_image = true."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}

variable "marketplace_plan" {
  description = "Plan de Marketplace para imágenes de terceros que lo requieren. Objeto con { name, product, publisher }."
  type = object({
    name      = string
    product   = string
    publisher = string
  })
  default = null
}

# ===================== CUSTOM DATA / USER DATA =====================

variable "custom_data" {
  description = "Script o configuración en base64 para cloud-init (Linux) o Custom Script (Windows). Se codificará automáticamente en base64 si no lo está."
  type        = string
  default     = null
  sensitive   = true
}

variable "user_data" {
  description = "User data para cloud-init (solo Linux, alternativa más moderna a custom_data). Se codificará automáticamente en base64."
  type        = string
  default     = null
  sensitive   = true
}

# ===================== SEGURIDAD AVANZADA =====================

variable "encryption_at_host_enabled" {
  description = "Habilita cifrado en el host para todos los discos (OS y Data). Requiere feature habilitado en la suscripción."
  type        = bool
  default     = false
}

variable "patch_mode" {
  description = "Modo de parcheo para Windows: 'AutomaticByOS', 'AutomaticByPlatform', 'Manual'. Para Linux: 'ImageDefault', 'AutomaticByPlatform'."
  type        = string
  default     = null
}

variable "patch_assessment_mode" {
  description = "Modo de evaluación de parches: 'ImageDefault' o 'AutomaticByPlatform'."
  type        = string
  default     = null
}

# ===================== AZURE HYBRID BENEFIT =====================

variable "license_type" {
  description = "Tipo de licencia para Azure Hybrid Benefit. Windows: 'Windows_Server' o 'Windows_Client'. Linux: 'RHEL_BYOS' o 'SLES_BYOS'."
  type        = string
  default     = null
}

# ===================== VM EXTENSIONS =====================

variable "enable_azure_monitor_agent" {
  description = "Instala Azure Monitor Agent (AMA) en la VM."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID del workspace de Log Analytics para Azure Monitor Agent. Requerido si enable_azure_monitor_agent = true."
  type        = string
  default     = null
}

variable "log_analytics_workspace_key" {
  description = "Clave primaria del workspace de Log Analytics. Requerida si enable_azure_monitor_agent = true."
  type        = string
  default     = null
  sensitive   = true
}

variable "custom_script_extension" {
  description = "Configuración para Custom Script Extension. Objeto con { file_uris, command_to_execute, storage_account_name?, storage_account_key? }."
  type = object({
    file_uris            = list(string)
    command_to_execute   = string
    storage_account_name = optional(string)
    storage_account_key  = optional(string)
  })
  default = null
}

# ===================== OTRAS CONFIGURACIONES =====================

variable "proximity_placement_group_id" {
  description = "ID del Proximity Placement Group para reducir latencia entre VMs."
  type        = string
  default     = null
}

variable "availability_set_id" {
  description = "ID del Availability Set (incompatible con zone)."
  type        = string
  default     = null
}

variable "dedicated_host_id" {
  description = "ID del Dedicated Host donde desplegar la VM."
  type        = string
  default     = null
}

variable "additional_capabilities_ultra_ssd_enabled" {
  description = "Habilita soporte para Ultra SSD data disks."
  type        = bool
  default     = false
}

# Redes
variable "enable_accelerated_networking" {
  description = "Habilita Accelerated Networking en la NIC (si el tamaño lo soporta)."
  type        = bool
  default     = false
}

# Boot diagnostics (opcional)
variable "boot_diagnostics_storage_uri" {
  description = "URI del Storage Account para boot diagnostics (opcional)."
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type = object({
    UDN       = string
    OWNER     = string
    xpeowner  = string
    proyecto  = string
    ambiente  = string
  })
}

# ===================== IP PRIVADA (Dinámica/Estática) =====================

variable "private_ip_version" {
  description = "Versión de IP privada: 'IPv4' o 'IPv6'."
  type        = string
  default     = "IPv4"
  validation {
    condition     = contains(["ipv4", "ipv6"], lower(var.private_ip_version))
    error_message = "private_ip_version debe ser 'IPv4' o 'IPv6'."
  }
}

variable "private_ip_allocation" {
  description = "Asignación de IP privada: 'Dynamic' o 'Static'."
  type        = string
  default     = "Dynamic"
  validation {
    condition     = contains(["dynamic", "static"], lower(var.private_ip_allocation))
    error_message = "private_ip_allocation debe ser 'Dynamic' o 'Static'."
  }
}

variable "private_ip_address" {
  description = "IP privada (requerida si private_ip_allocation = 'Static')."
  type        = string
  default     = null
  validation {
    condition     = lower(var.private_ip_allocation) != "static" || (var.private_ip_address != null && length(var.private_ip_address) > 0)
    error_message = "Debes especificar private_ip_address cuando private_ip_allocation = 'Static'."
  }
}
