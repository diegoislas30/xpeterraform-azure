resource "azurerm_container_group" "this" {
  name                = var.container_group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  dns_name_label      = var.dns_name_label
  ip_address_type     = var.ip_address_type
  restart_policy      = var.restart_policy

  dynamic "container" {
    for_each = var.containers
    content {
      name   = container.value.name
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      dynamic "ports" {
        for_each = lookup(container.value, "ports", [])
        content {
          port     = ports.value.port
          protocol = lookup(ports.value, "protocol", "TCP")
        }
      }

      dynamic "environment_variables" {
        for_each = lookup(container.value, "environment_variables", {})
        content {
          name  = environment_variables.key
          value = environment_variables.value
        }
      }

      dynamic "secure_environment_variables" {
        for_each = lookup(container.value, "secure_environment_variables", {})
        content {
          name  = secure_environment_variables.key
          value = secure_environment_variables.value
        }
      }

      dynamic "volume" {
        for_each = lookup(container.value, "volumes", [])
        content {
          name       = volume.value.name
          mount_path = volume.value.mount_path
          read_only  = lookup(volume.value, "read_only", false)

          share_name             = lookup(volume.value, "share_name", null)
          storage_account_name   = lookup(volume.value, "storage_account_name", null)
          storage_account_key    = lookup(volume.value, "storage_account_key", null)
        }
      }
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  dynamic "image_registry_credential" {
    for_each = var.image_registry_credentials
    content {
      server   = image_registry_credential.value.server
      username = image_registry_credential.value.username
      password = image_registry_credential.value.password
    }
  }

  dynamic "dns_config" {
    for_each = length(var.dns_servers) > 0 ? [1] : []
    content {
      nameservers = var.dns_servers
    }
  }

  tags = tomap(var.tags)
}
