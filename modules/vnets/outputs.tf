output "vnet_id" {
  description = "ID de la VNet"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Nombre de la VNet"
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "Espacio de direcciones de la VNet"
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "IDs de las subnets creadas (mapa: nombre => id)"
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "subnet_names" {
  description = "Nombres de las subnets creadas"
  value       = [for s in azurerm_subnet.this : s.name]
}

output "subnet_address_prefixes" {
  description = "Prefijos de direcciones de las subnets (mapa: nombre => address_prefixes)"
  value       = { for k, s in azurerm_subnet.this : k => s.address_prefixes }
}

output "subnets_full" {
  description = "Información completa de todas las subnets creadas"
  value = {
    for k, s in azurerm_subnet.this : k => {
      id               = s.id
      name             = s.name
      address_prefixes = s.address_prefixes
      service_endpoints = s.service_endpoints
    }
  }
}
