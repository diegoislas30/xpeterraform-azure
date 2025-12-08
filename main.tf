module "rg-scxpeicmprd" {
  source = "./modules/resource_group"
  resource_group_name = "rg-scxpeicmprd"
  location            = "southcentralus"
  tags = {
    UDN      = "Xpertal"
    OWNER    = "Martha Ibarra"
    xpeowner = "martha.ibarra@xpertal.com"
    proyecto = "ICM"
    ambiente = "Productivo"
  }
  providers = {
    azurerm = azurerm.Xpertal_XCS
  }
}

 module "vnetxpeicm-prd" {
   source              = "./modules/vnets"
   vnet_name           = "vnetxpeicm-prd"
   location            = module.rg-scxpeicmprd.resource_group_location
   resource_group_name = module.rg-scxpeicmprd.resource_group_name
   address_space       = ["172.29.80.160/27"]

   subnets = [

      {
        name           = "snet-xpeicm-prd"
        address_prefix = "172.29.80.160/27"
        service_endpoints = []
        delegation = {
          name = "Microsoft.Web/serverFarms"
          service_delegation = {
            name    = "Microsoft.Web/serverFarms"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
        private_endpoint_network_policies_enabled = false
      }
   ]

    tags = {
      UDN      = "Xpertal"
      OWNER    = "Martha Ibarra"
      xpeowner = "martha.ibarra@xpertal.com"
      proyecto = "ICM"
      ambiente = "Productivo"
    }

    providers = {
      azurerm = azurerm.Xpertal_XCS
    }
 }

module "xpe-vneticmsqlmidb-prd" {
   source              = "./modules/vnets"
   vnet_name           = "xpe-vneticmsqlmidb-prd"
   location            = module.rg-scxpeicmprd.resource_group_location
   resource_group_name = module.rg-scxpeicmprd.resource_group_name
   address_space       = ["172.29.80.192/27"]

   subnets = [

      {
        name           = "snet-xpeicm-prd"
        address_prefix = "172.29.80.192/27"
        service_endpoints = []
        delegation = {
          name = "Microsoft.Sql/managedInstances"
          service_delegation = {
            name    = "Microsoft.Sql/managedInstances"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
              "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
            ]
          }
        }
        private_endpoint_network_policies_enabled = false
      }
   ]

    tags = {
      UDN      = "Xpertal"
      OWNER    = "Martha Ibarra"
      xpeowner = "martha.ibarra@xpertal.com"
      proyecto = "ICM"
      ambiente = "Productivo"
    }

    providers = {
      azurerm = azurerm.Xpertal_XCS
    }
 }
   

module "rg-container-portalcostos-prd" {
  source = "./modules/resource_group"
  resource_group_name = "rg-container-portalcostos-prd"
  location = "southcentralus"
  tags = {
    UDN = "Xpertal"
    OWNER = "Diego Enrique Islas Cuervo"
    xpeowner = "diegoenrique.islas@xpertal.com"
    proyecto = "Portal de Costos"
    ambiente = "Productivo"
  }
  providers = {
    azurerm = azurerm.xpe_shared_poc
  }
}

module "acr" {
  source = "./modules/acr"
  resource_group_name = module.rg-container-portalcostos-prd.resource_group_name
  location            = module.rg-container-portalcostos-prd.resource_group_location
  acr_name            = "arctest"
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    UDN      = "Xpertal"
    OWNER    = "Diego Enrique Islas Cuervo"
    xpeowner = "diegoenrique.islas@xpertal.com"
    proyecto = "Portal de Costos"
    ambiente = "dev"
  }
  providers = {
    azurerm = azurerm.xpe_shared_poc
  }
}


