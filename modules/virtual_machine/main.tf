locals {
  is_trusted_launch       = lower(var.security_type) == "trustedlaunch"
  os_disk_caching_default = coalesce(var.os_disk_caching, "ReadWrite")

  # Mapear data_disks por LUN para crear y adjuntar discos gestionados
  data_disks_by_lun = { for d in var.data_disks : d.lun => d }

  # Normalizar asignación de IP privada
  ip_alloc = lower(var.private_ip_allocation) == "static" ? "Static" : "Dynamic"

  # Determinar si usar Marketplace image o custom image ID
  use_marketplace = var.use_marketplace_image && var.marketplace_image != null
  use_custom_id   = !var.use_marketplace_image && var.source_image_id != null

  # Validar que al menos una fuente de imagen esté configurada
  image_source_valid = local.use_marketplace || local.use_custom_id

  # Custom data encoding
  custom_data_encoded = var.custom_data != null ? (
    can(base64decode(var.custom_data)) ? var.custom_data : base64encode(var.custom_data)
  ) : null

  user_data_encoded = var.user_data != null ? (
    can(base64decode(var.user_data)) ? var.user_data : base64encode(var.user_data)
  ) : null

  # VM name for extensions
  vm_id = lower(var.os_type) == "linux" ? try(azurerm_linux_virtual_machine.this[0].id, null) : try(azurerm_windows_virtual_machine.this[0].id, null)
}

# NIC (sin IP pública, sin NSG en la NIC)
resource "azurerm_network_interface" "this" {
  name                          = "${var.vm_name}-nic"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_version    = var.private_ip_version
    private_ip_address_allocation = local.ip_alloc
    private_ip_address            = local.ip_alloc == "Static" ? var.private_ip_address : null
  }

  tags = var.tags
}

# ===================== LINUX =====================
resource "azurerm_linux_virtual_machine" "this" {
  count                           = lower(var.os_type) == "linux" ? 1 : 0
  name                            = var.vm_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.disable_password_authentication ? null : var.admin_password
  disable_password_authentication = var.disable_password_authentication
  network_interface_ids           = [azurerm_network_interface.this.id]
  zone                            = var.zone

  # Imagen desde SIG/Managed Image o Marketplace
  source_image_id = local.use_custom_id ? var.source_image_id : null

  dynamic "source_image_reference" {
    for_each = local.use_marketplace ? [1] : []
    content {
      publisher = var.marketplace_image.publisher
      offer     = var.marketplace_image.offer
      sku       = var.marketplace_image.sku
      version   = var.marketplace_image.version
    }
  }

  # Plan de Marketplace (para imágenes de terceros)
  dynamic "plan" {
    for_each = var.marketplace_plan != null ? [1] : []
    content {
      name      = var.marketplace_plan.name
      product   = var.marketplace_plan.product
      publisher = var.marketplace_plan.publisher
    }
  }

  # SSH Keys para autenticación segura
  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_keys
    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  # Seguridad
  vtpm_enabled              = local.is_trusted_launch
  secure_boot_enabled       = local.is_trusted_launch
  encryption_at_host_enabled = var.encryption_at_host_enabled

  # Azure Hybrid Benefit
  license_type = var.license_type

  # Patch Management
  patch_mode            = var.patch_mode
  patch_assessment_mode = var.patch_assessment_mode

  # Placement y Availability
  proximity_placement_group_id = var.proximity_placement_group_id
  availability_set_id          = var.availability_set_id
  dedicated_host_id            = var.dedicated_host_id

  # Ultra SSD support
  dynamic "additional_capabilities" {
    for_each = var.additional_capabilities_ultra_ssd_enabled ? [1] : []
    content {
      ultra_ssd_enabled = true
    }
  }

  # Cloud-init / Custom data
  custom_data = local.custom_data_encoded
  user_data   = local.user_data_encoded

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = contains(["userassigned", "systemassigned, userassigned"], lower(var.identity_type)) ? var.identity_ids : null
    }
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = local.os_disk_caching_default
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # Boot diagnostics (opcional)
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_uri == null ? [] : [1]
    content { storage_account_uri = var.boot_diagnostics_storage_uri }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = local.image_source_valid
      error_message = "Debes especificar source_image_id O configurar use_marketplace_image=true con marketplace_image."
    }
    precondition {
      condition     = var.disable_password_authentication == false || length(var.admin_ssh_keys) > 0
      error_message = "Para Linux con disable_password_authentication=true, debes proporcionar al menos una SSH key en admin_ssh_keys."
    }
  }
}

# ===================== WINDOWS =====================
resource "azurerm_windows_virtual_machine" "this" {
  count                 = lower(var.os_type) == "windows" ? 1 : 0
  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  provision_vm_agent    = true
  network_interface_ids = [azurerm_network_interface.this.id]
  zone                  = var.zone

  # Imagen desde SIG/Managed Image o Marketplace
  source_image_id = local.use_custom_id ? var.source_image_id : null

  dynamic "source_image_reference" {
    for_each = local.use_marketplace ? [1] : []
    content {
      publisher = var.marketplace_image.publisher
      offer     = var.marketplace_image.offer
      sku       = var.marketplace_image.sku
      version   = var.marketplace_image.version
    }
  }

  # Plan de Marketplace (para imágenes de terceros)
  dynamic "plan" {
    for_each = var.marketplace_plan != null ? [1] : []
    content {
      name      = var.marketplace_plan.name
      product   = var.marketplace_plan.product
      publisher = var.marketplace_plan.publisher
    }
  }

  # Seguridad
  vtpm_enabled               = local.is_trusted_launch
  secure_boot_enabled        = local.is_trusted_launch
  encryption_at_host_enabled = var.encryption_at_host_enabled

  # Azure Hybrid Benefit
  license_type = var.license_type

  # Patch Management
  patch_mode            = var.patch_mode
  patch_assessment_mode = var.patch_assessment_mode

  # Placement y Availability
  proximity_placement_group_id = var.proximity_placement_group_id
  availability_set_id          = var.availability_set_id
  dedicated_host_id            = var.dedicated_host_id

  # Ultra SSD support
  dynamic "additional_capabilities" {
    for_each = var.additional_capabilities_ultra_ssd_enabled ? [1] : []
    content {
      ultra_ssd_enabled = true
    }
  }

  # Custom data (scripts de inicialización)
  custom_data = local.custom_data_encoded

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = contains(["userassigned", "systemassigned, userassigned"], lower(var.identity_type)) ? var.identity_ids : null
    }
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = local.os_disk_caching_default
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_uri == null ? [] : [1]
    content { storage_account_uri = var.boot_diagnostics_storage_uri }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = local.image_source_valid
      error_message = "Debes especificar source_image_id O configurar use_marketplace_image=true con marketplace_image."
    }
    precondition {
      condition     = var.admin_password != null
      error_message = "admin_password es requerido para Windows VMs."
    }
  }
}

# ===================== DATA DISKS =====================

# Crear Managed Disks vacíos
resource "azurerm_managed_disk" "data" {
  for_each            = local.data_disks_by_lun
  name                = "${var.vm_name}-datadisk-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name

  storage_account_type = coalesce(try(each.value.storage_account_type, null), "StandardSSD_LRS")
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb

  tags = var.tags
}

# Adjuntar a VM Linux
resource "azurerm_virtual_machine_data_disk_attachment" "linux" {
  for_each           = lower(var.os_type) == "linux" ? azurerm_managed_disk.data : {}
  managed_disk_id    = each.value.id
  virtual_machine_id = azurerm_linux_virtual_machine.this[0].id
  lun                = each.key
  caching            = coalesce(try(local.data_disks_by_lun[each.key].caching, null), "ReadOnly")
}

# Adjuntar a VM Windows
resource "azurerm_virtual_machine_data_disk_attachment" "windows" {
  for_each           = lower(var.os_type) == "windows" ? azurerm_managed_disk.data : {}
  managed_disk_id    = each.value.id
  virtual_machine_id = azurerm_windows_virtual_machine.this[0].id
  lun                = each.key
  caching            = coalesce(try(local.data_disks_by_lun[each.key].caching, null), "ReadOnly")
}

# ===================== VM EXTENSIONS =====================

# Azure Monitor Agent para Linux
resource "azurerm_virtual_machine_extension" "azure_monitor_linux" {
  count                      = var.enable_azure_monitor_agent && lower(var.os_type) == "linux" ? 1 : 0
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.this[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.28"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  settings = jsonencode({
    workspaceId = var.log_analytics_workspace_id
  })

  protected_settings = jsonencode({
    workspaceKey = var.log_analytics_workspace_key
  })

  tags = var.tags
}

# Azure Monitor Agent para Windows
resource "azurerm_virtual_machine_extension" "azure_monitor_windows" {
  count                      = var.enable_azure_monitor_agent && lower(var.os_type) == "windows" ? 1 : 0
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.this[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.22"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  settings = jsonencode({
    workspaceId = var.log_analytics_workspace_id
  })

  protected_settings = jsonencode({
    workspaceKey = var.log_analytics_workspace_key
  })

  tags = var.tags
}

# Custom Script Extension para Linux
resource "azurerm_virtual_machine_extension" "custom_script_linux" {
  count                      = var.custom_script_extension != null && lower(var.os_type) == "linux" ? 1 : 0
  name                       = "CustomScriptExtension"
  virtual_machine_id         = azurerm_linux_virtual_machine.this[0].id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = var.custom_script_extension.file_uris
  })

  protected_settings = jsonencode(merge(
    {
      commandToExecute = var.custom_script_extension.command_to_execute
    },
    var.custom_script_extension.storage_account_name != null ? {
      storageAccountName = var.custom_script_extension.storage_account_name
      storageAccountKey  = var.custom_script_extension.storage_account_key
    } : {}
  ))

  tags = var.tags
}

# Custom Script Extension para Windows
resource "azurerm_virtual_machine_extension" "custom_script_windows" {
  count                      = var.custom_script_extension != null && lower(var.os_type) == "windows" ? 1 : 0
  name                       = "CustomScriptExtension"
  virtual_machine_id         = azurerm_windows_virtual_machine.this[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = var.custom_script_extension.file_uris
  })

  protected_settings = jsonencode(merge(
    {
      commandToExecute = var.custom_script_extension.command_to_execute
    },
    var.custom_script_extension.storage_account_name != null ? {
      storageAccountName = var.custom_script_extension.storage_account_name
      storageAccountKey  = var.custom_script_extension.storage_account_key
    } : {}
  ))

  tags = var.tags
}
