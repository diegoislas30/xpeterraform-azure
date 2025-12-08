output "container_group_id" {
  description = "The ID of the Container Group"
  value       = azurerm_container_group.this.id
}

output "container_group_name" {
  description = "The name of the Container Group"
  value       = azurerm_container_group.this.name
}

output "ip_address" {
  description = "The IP address allocated to the container group"
  value       = azurerm_container_group.this.ip_address
}

output "fqdn" {
  description = "The FQDN of the container group derived from dns_name_label"
  value       = azurerm_container_group.this.fqdn
}

output "identity" {
  description = "The identity block of the Container Group"
  value       = azurerm_container_group.this.identity
}
