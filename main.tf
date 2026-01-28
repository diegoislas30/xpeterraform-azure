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
      azurerm                = azurerm.Xpertal_XCS
      azurerm.peering_remote = azurerm.Xpertal_XCS
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
      azurerm                = azurerm.Xpertal_XCS
      azurerm.peering_remote = azurerm.Xpertal_XCS
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
   address_space       = ["172.29.67.96/27"]

   subnets = [
    {
      name           = "snet-xpeperfiles-sailtpointqa"
      address_prefix = "172.29.67.96/27"
    }
  ]

  peerings = [
    {
      name             = "pe-tovnet-vnet-xpeperfiles-sailtpointqa-to-vnet-xpe-seg-core"
      remote_vnet_id   = data.azurerm_virtual_network.seg-core.id
      remote_vnet_name = data.azurerm_virtual_network.seg-core.name
      remote_rg_name   = "RG-XPESEG-PACORE"

      local = {
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = false
        use_remote_gateways          = false
      }

      remote = {
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = false
        use_remote_gateways          = false
      }
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
      azurerm                = azurerm.xpeperfiles-xcs
      azurerm.peering_remote = azurerm.xpertal_shared_xcs
    }
  }

  module "vnet-xpeperfiles-sailtpointprd" {
    source              = "./modules/vnets"
    vnet_name           = "vnet-xpeperfiles-sailtpointprd"
    location            = module.rg-scxpesailpointprd.resource_group_location
    resource_group_name = module.rg-scxpesailpointprd.resource_group_name
    address_space       = ["172.29.67.128/27"]

    subnets = [
     {
       name           = "snet-xpeperfiles-sailtpointprd"
       address_prefix = "172.29.67.128/27"
     }
   ]

   peerings = [
     {
       name             = "pe-vnet-xpeperfiles-sailtpointprd-to-vnet-xpe-seg-core"
       remote_vnet_id   = data.azurerm_virtual_network.seg-core.id
       remote_vnet_name = data.azurerm_virtual_network.seg-core.name
       remote_rg_name   = "RG-XPESEG-PACORE"

       local = {
         allow_virtual_network_access = true
         allow_forwarded_traffic      = true
         allow_gateway_transit        = false
         use_remote_gateways          = false
       }

       remote = {
         allow_virtual_network_access = true
         allow_forwarded_traffic      = true
         allow_gateway_transit        = false
         use_remote_gateways          = false
       }
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
       azurerm                = azurerm.xpeperfiles-xcs
       azurerm.peering_remote = azurerm.xpertal_shared_xcs
     }
   }

# =============================================================================
# NSGs para SailPoint - Desplegados desde Template Spec
# =============================================================================

# NSG para SailPoint QA
resource "azurerm_resource_group_template_deployment" "nsg-sailpoint-qa" {
  name                = "nsg-xpeperfiles-sailtpointqa-deployment"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = data.azurerm_template_spec_version.nsgxcs.template_body

  parameters_content = jsonencode({
    nsg_name = { value = "nsg-xpeperfiles-sailtpointqa" }
  })

  provider = azurerm.xpeperfiles-xcs
}

# NSG para SailPoint PRD
resource "azurerm_resource_group_template_deployment" "nsg-sailpoint-prd" {
  name                = "nsg-xpeperfiles-sailtpointprd-deployment"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = data.azurerm_template_spec_version.nsgxcs.template_body

  parameters_content = jsonencode({
    nsg_name = { value = "nsg-xpeperfiles-sailtpointprd" }
  })

  provider = azurerm.xpeperfiles-xcs
}

# Data sources para obtener los NSGs creados por el template
data "azurerm_network_security_group" "nsg-sailpoint-qa" {
  name                = "nsg-xpeperfiles-sailtpointqa"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  provider            = azurerm.xpeperfiles-xcs

  depends_on = [azurerm_resource_group_template_deployment.nsg-sailpoint-qa]
}

data "azurerm_network_security_group" "nsg-sailpoint-prd" {
  name                = "nsg-xpeperfiles-sailtpointprd"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  provider            = azurerm.xpeperfiles-xcs

  depends_on = [azurerm_resource_group_template_deployment.nsg-sailpoint-prd]
}

# Asociación de NSG a Subnet QA
resource "azurerm_subnet_network_security_group_association" "sailpoint-qa" {
  subnet_id                 = module.vnet-xpeperfiles-sailtpointqa.subnet_ids["snet-xpeperfiles-sailtpointqa"]
  network_security_group_id = data.azurerm_network_security_group.nsg-sailpoint-qa.id
}

# Asociación de NSG a Subnet PRD
resource "azurerm_subnet_network_security_group_association" "sailpoint-prd" {
  subnet_id                 = module.vnet-xpeperfiles-sailtpointprd.subnet_ids["snet-xpeperfiles-sailtpointprd"]
  network_security_group_id = data.azurerm_network_security_group.nsg-sailpoint-prd.id
}

# =============================================================================
# VMs SailPoint QA - Windows Server 2022 desde Shared Image Gallery
# =============================================================================

module "vmscxpeazureqa01" {
  source              = "./modules/virtual_machine"
  vm_name             = "vmscxpeazureqa01"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  location            = module.rg-scxpesailpointqa.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointqa.subnet_ids["snet-xpeperfiles-sailtpointqa"]
  os_type             = "windows"
  vm_size             = "Standard_D8s_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  disable_password_authentication = false

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

module "vmscxpeiqserviceqa01" {
  source              = "./modules/virtual_machine"
  vm_name             = "vmscxpeiqserviceqa01"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  location            = module.rg-scxpesailpointqa.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointqa.subnet_ids["snet-xpeperfiles-sailtpointqa"]
  os_type             = "windows"
  vm_size             = "Standard_D2_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 50
  disable_password_authentication = false

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

module "vmscxpevaqa01" {
  source              = "./modules/virtual_machine"
  vm_name             = "vmscxpevaqa01"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  location            = module.rg-scxpesailpointqa.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointqa.subnet_ids["snet-xpeperfiles-sailtpointqa"]
  os_type             = "windows"
  vm_size             = "Standard_D8s_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  disable_password_authentication = false

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

# =============================================================================
# VMs SailPoint PRD - Windows Server 2022 desde Shared Image Gallery
# =============================================================================

module "vmscxpeazureprd01" {
  source              = "./modules/virtual_machine"
  vm_name             = "vmscxpeazureprd01"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  location            = module.rg-scxpesailpointprd.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointprd.subnet_ids["snet-xpeperfiles-sailtpointprd"]
  os_type             = "windows"
  vm_size             = "Standard_D8s_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  disable_password_authentication = false

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

module "vmscxpeiqserviceprd01" {
  source              = "./modules/virtual_machine"
  vm_name             = "vmscxpeiqserviceprd01"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  location            = module.rg-scxpesailpointprd.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointprd.subnet_ids["snet-xpeperfiles-sailtpointprd"]
  os_type             = "windows"
  vm_size             = "Standard_D4d_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 250
  disable_password_authentication = false

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

module "vmscxpevaprd01" {
  source              = "./modules/virtual_machine"
  vm_name             = "vmscxpevaprd01"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  location            = module.rg-scxpesailpointprd.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointprd.subnet_ids["snet-xpeperfiles-sailtpointprd"]
  os_type             = "windows"
  vm_size             = "Standard_D8s_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  disable_password_authentication = false

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
