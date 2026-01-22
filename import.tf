# ====================================================================
# RECURSO IMPORTADO DESDE AZURE
# ====================================================================
#
# Tipo de recurso: virtual_network
# Nombre en Azure:  vnet-xpesegti01
# Resource Group:   rg-scsegvnet
# Fecha de import:  2026-01-22 18:41:38 UTC
# Importado por:    diegoislas30
# Workflow run:     https://github.com/diegoislas30/xpeterraform-azure/actions/runs/21260546457
#
# Comando usado:
# terraform import azurerm_virtual_network.vnet-xpesegti01 /subscriptions/5c589577-440f-428c-baeb-bf0999fc3586/resourceGroups/rg-scsegvnet/providers/Microsoft.Network/virtualNetworks/vnet-xpesegti01
#
# ====================================================================

resource "azurerm_virtual_network" "vnet-xpesegti01" {
  name                = "vnet-xpesegti01"
  resource_group_name = "rg-scsegvnet"
  location            = "southcentralus"
  address_space       = ["172.29.83.0/24"]

  tags = {
  "OWNER": "Ezequiel Cedillo",
  "UDN": "XPERTAL"
}
}
