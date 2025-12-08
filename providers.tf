terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.116" }
  }
}

# Provider por defecto (sin alias) - Usando Xpertal_XCS
provider "azurerm" {
  features {}
  subscription_id = "6d94fbd2-8182-4943-a9b3-53d236df5469"
}

provider "azurerm" {
  alias = "xpe_shared_poc"
  features {}
  subscription_id = "bc444e87-bfcd-4aeb-93f9-9a52b1089062"
}

provider "azurerm" {
  alias = "XPERTAL-Shared-xcs"
  features {}
  subscription_id = "9442ead9-7f87-4f7a-b248-53e511abefd7"
}

provider "azurerm" {
  alias = "Xpertal_XCS"
  features {}
  subscription_id = "6d94fbd2-8182-4943-a9b3-53d236df5469"
}




