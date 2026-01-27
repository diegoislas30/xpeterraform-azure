terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
      configuration_aliases = [
        azurerm,              # Provider principal para la VNet y subnets
        azurerm.peering_remote # Provider para crear peerings en VNets remotas (opcional)
      ]
    }
  }
}