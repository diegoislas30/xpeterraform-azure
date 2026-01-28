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

# Template Spec para NSG estándar de XCS
# Contiene las reglas de seguridad base para todas las VNets
data "azurerm_template_spec_version" "nsgxcs" {
  name                = "nsgxcs-template"
  resource_group_name = "rg-ImageTemplate_Xpertal"
  version             = "v2.0"
  provider            = azurerm.xpertal_shared_xcs
}

# Imagen Windows Server 2022 desde Shared Image Gallery
data "azurerm_shared_image_version" "windows2022" {
  name                = "1.0.0"
  image_name          = "Windows_2022"
  gallery_name        = "XpertalSharedImageWindows"
  resource_group_name = "rg-ImageTemplate_Xpertal"
  provider            = azurerm.xpertal_shared_xcs
}
