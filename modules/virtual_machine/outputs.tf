output "vm_id" {
  description = "ID de la VM creada."
  value       = try(azurerm_linux_virtual_machine.this[0].id, azurerm_windows_virtual_machine.this[0].id)
}

output "vm_name" {
  description = "Nombre de la VM."
  value       = var.vm_name
}

output "nic_id" {
  description = "ID de la NIC principal."
  value       = azurerm_network_interface.this.id
}

output "private_ip" {
  description = "IP privada asignada a la NIC."
  value       = azurerm_network_interface.this.ip_configuration[0].private_ip_address
}

output "principal_id" {
  description = "Principal ID de la System Assigned Managed Identity (si está habilitada)."
  value = try(
    azurerm_linux_virtual_machine.this[0].identity[0].principal_id,
    azurerm_windows_virtual_machine.this[0].identity[0].principal_id,
    null
  )
}

output "identity" {
  description = "Objeto completo de identity de la VM con type, principal_id y identity_ids."
  value = try(
    azurerm_linux_virtual_machine.this[0].identity[0],
    azurerm_windows_virtual_machine.this[0].identity[0],
    null
  )
}

output "data_disk_ids" {
  description = "Mapa de LUN a IDs de data disks adjuntados a la VM."
  value = {
    for lun, disk in azurerm_managed_disk.data : lun => disk.id
  }
}

output "os_disk_id" {
  description = "ID del OS disk."
  value = try(
    azurerm_linux_virtual_machine.this[0].os_disk[0].name,
    azurerm_windows_virtual_machine.this[0].os_disk[0].name,
    null
  )
}

output "os_type" {
  description = "Tipo de sistema operativo (linux o windows)."
  value       = lower(var.os_type)
}

output "vm_size" {
  description = "Tamaño de la VM."
  value       = var.vm_size
}

output "location" {
  description = "Ubicación de la VM."
  value       = var.location
}

output "resource_group_name" {
  description = "Nombre del Resource Group."
  value       = var.resource_group_name
}
