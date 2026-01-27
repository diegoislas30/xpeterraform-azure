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


 module "rg-scxpesailpointqa" {
   source = "./modules/resource_group"
   resource_group_name = "rg-scxpesailpointqa"
   location            = "southcentralus"
   tags = {
     UDN      = "Xpertal"
     OWNER    = "Felipe Alvarado"
     xpeowner = "felipe.alvarado@xpertal.com"
     proyecto = "SailPoint"
     ambiente = "QA"
   }
   providers = {
     azurerm = azurerm.xpeperfiles-xcs
   }
 }

 module "rg-scxpesailpointprd" {
   source = "./modules/resource_group"
   resource_group_name = "rg-scxpesailpointprd"
   location            = "southcentralus"
   tags = {
     UDN      = "Xpertal"
     OWNER    = "Felipe Alvarado"
     xpeowner = "felipe.alvarado@xpertal.com"
     proyecto = "SailPoint"
     ambiente = "Productivo"
   }
   providers = {
     azurerm = azurerm.xpeperfiles-xcs
   }
 }

 module "vnet-xpeperfiles-sailtpointqa" {
   source              = "./modules/vnets"
   vnet_name           = "vnet-xpeperfiles-sailtpointqa"
   location            = module.rg-scxpesailpointqa.resource_group_location
   resource_group_name = module.rg-scxpesailpointqa.resource_group_name
   address_space       = ["172.29.80.160/27"]
   subnets = [
      {
        name           = "snet-xpeperfiles-sailtpointqa"
        address_prefix = "172.29.80.160/27"
        service_endpoints = []
        delegation = []
        private_endpoint_network_policies_enabled = false
      }
   ]
   tags = {
     UDN      = "Xpertal"
     OWNER    = "Felipe Alvarado"
     xpeowner = "felipe.alvarado@xpertal.com"
     proyecto = "SailPoint"
     ambiente = "QA"
   }
   providers = {
     azurerm = azurerm.xpeperfiles-xcs
    }
  }

module "vnet-xpeperfiles-sailtpointprd" {
   source              = "./modules/vnets"
   vnet_name           = "vnet-xpeperfiles-sailtpointprd"
   location            = module.rg-scxpesailpointprd.resource_group_location
   resource_group_name = module.rg-scxpesailpointprd.resource_group_name
   address_space       = ["172.29.80.192/27"]
   subnets = [
      {
        name           = "snet-xpeperfiles-sailtpointprd"
        address_prefix = "172.29.80.192/27"
        service_endpoints = []
        delegation = []
        private_endpoint_network_policies_enabled = false
      }
   ]
   tags = {
     UDN      = "Xpertal"
     OWNER    = "Felipe Alvarado"
     xpeowner = "felipe.alvarado@xpertal.com"
     proyecto = "SailPoint"
     ambiente = "Productivo"
   }
   providers = {
     azurerm = azurerm.xpeperfiles-xcs
    }
  }
   




