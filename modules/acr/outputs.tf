output "acr_id" {
  description = "The ID of the Container Registry"
  value       = azurerm_container_registry.this.id
}

output "acr_name" {
  description = "The name of the Container Registry"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "The URL that can be used to log into the container registry"
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "The Username associated with the Container Registry Admin account"
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_username : null
  sensitive   = true
}

output "admin_password" {
  description = "The Password associated with the Container Registry Admin account"
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_password : null
  sensitive   = true
}

output "identity" {
  description = "The identity block of the Container Registry"
  value       = azurerm_container_registry.this.identity
}

output "sku" {
  description = "The SKU of the Container Registry"
  value       = azurerm_container_registry.this.sku
}
