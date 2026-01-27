# =============================================================================
# Data Sources - Recursos existentes (solo lectura)
# =============================================================================

# VNet Core de Seguridad - Palo Alto Firewall
# Esta VNet NO es gestionada por Terraform, solo se referencia para peerings
data "azurerm_virtual_network" "seg-core" {
  name                = "vnet-xpe-seg-core"
  resource_group_name = "RG-XPESEG-PACORE"
  provider            = azurerm.xpertal_shared_xcs
}
