# Test: Verificación de pipeline - 2026-01-30

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

# ======================================================
# Recursos para SailPoint INICIO
# ======================================================


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
        use_remote_gateways          = true
      }

      remote = {
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = true
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
         use_remote_gateways          = true
       }

       remote = {
         allow_virtual_network_access = true
         allow_forwarded_traffic      = true
         allow_gateway_transit        = true
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
  computer_name       = "vmscazureqa01"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  location            = module.rg-scxpesailpointqa.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointqa.subnet_ids["snet-xpeperfiles-sailtpointqa"]
  os_type             = "windows"
  vm_size             = "Standard_D8s_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  security_type       = "Standard"
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
  computer_name       = "vmsciqsvcqa01"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  location            = module.rg-scxpesailpointqa.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointqa.subnet_ids["snet-xpeperfiles-sailtpointqa"]
  os_type             = "windows"
  vm_size             = "Standard_D2_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  security_type       = "Standard"
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
  computer_name       = "vmscvaqa01"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  location            = module.rg-scxpesailpointqa.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointqa.subnet_ids["snet-xpeperfiles-sailtpointqa"]
  os_type             = "windows"
  vm_size             = "Standard_D8s_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  security_type       = "Standard"
  disable_password_authentication = false

  data_disks = [
    {
      lun                  = 0
      size_gb              = 100
      caching              = "ReadWrite"
      storage_account_type = "StandardSSD_LRS"
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

# =============================================================================
# VMs SailPoint PRD - Windows Server 2022 desde Shared Image Gallery
# =============================================================================

module "vmscxpeazureprd01" {
  source              = "./modules/virtual_machine"
  vm_name             = "vmscxpeazureprd01"
  computer_name       = "vmscazureprd01"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  location            = module.rg-scxpesailpointprd.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointprd.subnet_ids["snet-xpeperfiles-sailtpointprd"]
  os_type             = "windows"
  vm_size             = "Standard_D8s_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  security_type       = "Standard"
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
  computer_name       = "vmsciqsvcprd01"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  location            = module.rg-scxpesailpointprd.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointprd.subnet_ids["snet-xpeperfiles-sailtpointprd"]
  os_type             = "windows"
  vm_size             = "Standard_D4d_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 250
  security_type       = "Standard"
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
  computer_name       = "vmscvaprd01"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  location            = module.rg-scxpesailpointprd.resource_group_location
  subnet_id           = module.vnet-xpeperfiles-sailtpointprd.subnet_ids["snet-xpeperfiles-sailtpointprd"]
  os_type             = "windows"
  vm_size             = "Standard_D8s_v5"
  source_image_id     = data.azurerm_shared_image_version.windows2022.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  os_disk_size_gb     = 128
  security_type       = "Standard"
  disable_password_authentication = false

  data_disks = [
    {
      lun                  = 0
      size_gb              = 100
      caching              = "ReadWrite"
      storage_account_type = "StandardSSD_LRS"
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

# =============================================================================
# Azure Backup - Recovery Services Vaults y Políticas
# =============================================================================

# Recovery Services Vault para QA
resource "azurerm_recovery_services_vault" "sailpoint-qa" {
  name                = "rsv-xpeperfiles-sailpointqa"
  location            = module.rg-scxpesailpointqa.resource_group_location
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  sku                 = "Standard"
  soft_delete_enabled = true

  tags = {
    UDN      = "Xpertal"
    OWNER    = "Felipe Alvarado"
    xpeowner = "felipe.alvarado@xpertal.com"
    proyecto = "SailPoint"
    ambiente = "QA"
  }

  provider = azurerm.xpeperfiles-xcs
}

# Recovery Services Vault para PRD
resource "azurerm_recovery_services_vault" "sailpoint-prd" {
  name                = "rsv-xpeperfiles-sailpointprd"
  location            = module.rg-scxpesailpointprd.resource_group_location
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  sku                 = "Standard"
  soft_delete_enabled = true

  tags = {
    UDN      = "Xpertal"
    OWNER    = "Felipe Alvarado"
    xpeowner = "felipe.alvarado@xpertal.com"
    proyecto = "SailPoint"
    ambiente = "Productivo"
  }

  provider = azurerm.xpeperfiles-xcs
}

# Política de Backup QA - Diario con retención 30 días
resource "azurerm_backup_policy_vm" "sailpoint-qa" {
  name                = "policy-vm-daily-30days-qa"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.sailpoint-qa.name

  timezone = "Central Standard Time"

  backup {
    frequency = "Daily"
    time      = "02:00"
  }

  retention_daily {
    count = 30
  }

  provider = azurerm.xpeperfiles-xcs
}

# Política de Backup PRD - Diario con retención 30 días
resource "azurerm_backup_policy_vm" "sailpoint-prd" {
  name                = "policy-vm-daily-30days-prd"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.sailpoint-prd.name

  timezone = "Central Standard Time"

  backup {
    frequency = "Daily"
    time      = "02:00"
  }

  retention_daily {
    count = 30
  }

  provider = azurerm.xpeperfiles-xcs
}

# =============================================================================
# Backup Protection - VMs QA
# =============================================================================

resource "azurerm_backup_protected_vm" "vmscxpeazureqa01" {
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.sailpoint-qa.name
  source_vm_id        = module.vmscxpeazureqa01.vm_id
  backup_policy_id    = azurerm_backup_policy_vm.sailpoint-qa.id

  provider = azurerm.xpeperfiles-xcs
}

resource "azurerm_backup_protected_vm" "vmscxpeiqserviceqa01" {
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.sailpoint-qa.name
  source_vm_id        = module.vmscxpeiqserviceqa01.vm_id
  backup_policy_id    = azurerm_backup_policy_vm.sailpoint-qa.id

  provider = azurerm.xpeperfiles-xcs
}

resource "azurerm_backup_protected_vm" "vmscxpevaqa01" {
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.sailpoint-qa.name
  source_vm_id        = module.vmscxpevaqa01.vm_id
  backup_policy_id    = azurerm_backup_policy_vm.sailpoint-qa.id

  provider = azurerm.xpeperfiles-xcs
}

# =============================================================================
# Backup Protection - VMs PRD
# =============================================================================

resource "azurerm_backup_protected_vm" "vmscxpeazureprd01" {
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.sailpoint-prd.name
  source_vm_id        = module.vmscxpeazureprd01.vm_id
  backup_policy_id    = azurerm_backup_policy_vm.sailpoint-prd.id

  provider = azurerm.xpeperfiles-xcs
}

resource "azurerm_backup_protected_vm" "vmscxpeiqserviceprd01" {
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.sailpoint-prd.name
  source_vm_id        = module.vmscxpeiqserviceprd01.vm_id
  backup_policy_id    = azurerm_backup_policy_vm.sailpoint-prd.id

  provider = azurerm.xpeperfiles-xcs
}

resource "azurerm_backup_protected_vm" "vmscxpevaprd01" {
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.sailpoint-prd.name
  source_vm_id        = module.vmscxpevaprd01.vm_id
  backup_policy_id    = azurerm_backup_policy_vm.sailpoint-prd.id

  provider = azurerm.xpeperfiles-xcs
}

# =============================================================================
# Microsoft Defender for Cloud - Servers Plan 2
# =============================================================================

# Habilitar Defender for Servers Plan 2 en la suscripción
resource "azurerm_security_center_subscription_pricing" "defender-servers" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
  subplan       = "P2"

  provider = azurerm.xpeperfiles-xcs
}

# =============================================================================
# Route Tables para SailPoint
# =============================================================================

# Route Table para SailPoint QA
module "rt-xpeperfiles-sailpointqa" {
  source              = "./modules/route_table"
  rt_name             = "rt-xpeperfiles-sailpointqa"
  resource_group_name = module.rg-scxpesailpointqa.resource_group_name
  location            = module.rg-scxpesailpointqa.resource_group_location

  routes = [
    {
      name                   = "DefaultInternet"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "RedDCAZ"
      address_prefix         = "172.29.104.0/21"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "RedXpertal"
      address_prefix         = "10.0.0.0/8"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanDMZcomunitaria"
      address_prefix         = "192.168.198.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanHCM"
      address_prefix         = "172.29.49.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanHCM_dev"
      address_prefix         = "172.29.56.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanHCM_prd"
      address_prefix         = "172.29.50.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanPTM_prd"
      address_prefix         = "172.29.112.0/27"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-vnet2dnsresolv"
      address_prefix         = "172.29.99.4/32"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt_lanvnetintegrationICM"
      address_prefix         = "172.29.67.32/27"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt_svr_CSCMSSFTP"
      address_prefix         = "192.168.198.66/32"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rttovnetimbera"
      address_prefix         = "172.29.63.0/26"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
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

# Route Table para SailPoint PRD
module "rt-xpeperfiles-sailpointprd" {
  source              = "./modules/route_table"
  rt_name             = "rt-xpeperfiles-sailpointprd"
  resource_group_name = module.rg-scxpesailpointprd.resource_group_name
  location            = module.rg-scxpesailpointprd.resource_group_location

  routes = [
    {
      name                   = "DefaultInternet"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "RedDCAZ"
      address_prefix         = "172.29.104.0/21"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "RedXpertal"
      address_prefix         = "10.0.0.0/8"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanDMZcomunitaria"
      address_prefix         = "192.168.198.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanHCM"
      address_prefix         = "172.29.49.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanHCM_dev"
      address_prefix         = "172.29.56.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanHCM_prd"
      address_prefix         = "172.29.50.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-lanPTM_prd"
      address_prefix         = "172.29.112.0/27"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt-vnet2dnsresolv"
      address_prefix         = "172.29.99.4/32"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt_lanvnetintegrationICM"
      address_prefix         = "172.29.67.32/27"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rt_svr_CSCMSSFTP"
      address_prefix         = "192.168.198.66/32"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
    },
    {
      name                   = "rttovnetimbera"
      address_prefix         = "172.29.63.0/26"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.29.97.4"
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

# Asociación de Route Table a Subnet QA
resource "azurerm_subnet_route_table_association" "sailpoint-qa" {
  subnet_id      = module.vnet-xpeperfiles-sailtpointqa.subnet_ids["snet-xpeperfiles-sailtpointqa"]
  route_table_id = module.rt-xpeperfiles-sailpointqa.rt_id
}

# Asociación de Route Table a Subnet PRD
resource "azurerm_subnet_route_table_association" "sailpoint-prd" {
  subnet_id      = module.vnet-xpeperfiles-sailtpointprd.subnet_ids["snet-xpeperfiles-sailtpointprd"]
  route_table_id = module.rt-xpeperfiles-sailpointprd.rt_id
}

# =============================================================================
# Rutas adicionales en rt-er2poc-test (Route Table existente)
# Para alcanzar las VNets de SailPoint desde ExpressRoute
# =============================================================================

# Ruta hacia VNet SailPoint QA (172.29.67.96/27)
resource "azurerm_route" "rt2LANCloud46" {
  name                   = "rt2LANCloud46"
  resource_group_name    = "rg-xpeseg-test"
  route_table_name       = data.azurerm_route_table.rt-er2poc-test.name
  address_prefix         = "172.29.67.96/27"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "172.29.97.116"

  provider = azurerm.xpertal_shared_xcs
}

# Ruta hacia VNet SailPoint PRD (172.29.67.128/27)
resource "azurerm_route" "rt2LANCloud47" {
  name                   = "rt2LANCloud47"
  resource_group_name    = "rg-xpeseg-test"
  route_table_name       = data.azurerm_route_table.rt-er2poc-test.name
  address_prefix         = "172.29.67.128/27"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "172.29.97.116"

  provider = azurerm.xpertal_shared_xcs
}

# =============================================================================
# Recursos para SailPoint FIN
# =============================================================================

