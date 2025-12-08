resource "azurerm_container_registry" "this" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  # Network rule set (only for Premium SKU)
  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" && var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = lookup(network_rule_set.value, "ip_rules", [])
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }

      dynamic "virtual_network" {
        for_each = lookup(network_rule_set.value, "virtual_network_subnet_ids", [])
        content {
          action    = "Allow"
          subnet_id = virtual_network.value
        }
      }
    }
  }

  # Geo-replication (only for Premium SKU)
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = lookup(georeplications.value, "zone_redundancy_enabled", false)
      tags                    = tomap(var.tags)
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  # Encryption (only for Premium SKU)
  dynamic "encryption" {
    for_each = var.sku == "Premium" && var.encryption != null ? [var.encryption] : []
    content {
      enabled            = true
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  # Retention policy (only for Premium SKU)
  dynamic "retention_policy" {
    for_each = var.sku == "Premium" && var.retention_policy_days != null ? [1] : []
    content {
      days    = var.retention_policy_days
      enabled = true
    }
  }

  # Trust policy (only for Premium SKU)
  dynamic "trust_policy" {
    for_each = var.sku == "Premium" && var.trust_policy_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  # Quarantine policy (only for Premium SKU)
  quarantine_policy_enabled = var.sku == "Premium" ? var.quarantine_policy_enabled : false

  # Zone redundancy (only for Premium SKU)
  zone_redundancy_enabled = var.sku == "Premium" ? var.zone_redundancy_enabled : false

  # Export policy
  export_policy_enabled = var.export_policy_enabled

  # Anonymous pull
  anonymous_pull_enabled = var.anonymous_pull_enabled

  # Data endpoint
  data_endpoint_enabled = var.data_endpoint_enabled

  # Network rule bypass option
  network_rule_bypass_option = var.network_rule_bypass_option

  tags = tomap(var.tags)
}
