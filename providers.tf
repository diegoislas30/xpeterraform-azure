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

# =============================================================================
# Suscripciones Azure
# =============================================================================

provider "azurerm" {
  alias                  = "cscp_xcs"
  features {}
  subscription_id        = "ca6c31c5-9ab0-40d6-b9ec-5ac94ed24da2"
  skip_provider_registration = true
}

provider "azurerm" {
  alias           = "digital_fnd_xcs"
  features {}
  subscription_id = "27ca0ab9-537a-49cd-ae50-f38289c7c4c1"
}

provider "azurerm" {
  alias           = "femco_xcs"
  features {}
  subscription_id = "68af4de4-8a47-48aa-ab62-9c8f7eb8e7f7"
}

provider "azurerm" {
  alias           = "femsa_xcs"
  features {}
  subscription_id = "261c4541-bb41-4c7b-83ed-e11a5e3dd89e"
}

provider "azurerm" {
  alias           = "femsaaudint_xcs"
  features {}
  subscription_id = "a0411f53-ec11-434a-a763-f0832d6ce9df"
}

provider "azurerm" {
  alias           = "femsaayc_xcs"
  features {}
  subscription_id = "d56b3ec3-23fb-4b99-b4fc-4a98155b2ae8"
}

provider "azurerm" {
  alias           = "ms_azure_enterprise_1"
  features {}
  subscription_id = "05afc062-ff6a-4191-86f4-50a874874544"
}

provider "azurerm" {
  alias           = "ms_azure_enterprise_2"
  features {}
  subscription_id = "43eac18a-45a9-4b1c-be3a-4a57393265d6"
}

provider "azurerm" {
  alias           = "ms_azure_enterprise_3"
  features {}
  subscription_id = "67f3321a-d96e-4be9-84c3-47fbf08b856e"
}

provider "azurerm" {
  alias           = "ms_azure_enterprise_4"
  features {}
  subscription_id = "c0282d00-5241-4077-a3f1-709f242e4975"
}

provider "azurerm" {
  alias           = "suscripcion_azure_1"
  features {}
  subscription_id = "5ab97b15-0ba4-4881-a325-b4c129782ab6"
}

provider "azurerm" {
  alias           = "suscripcion_azure_2"
  features {}
  subscription_id = "d265b160-99af-4208-9823-97ef47d3c9d2"
}

provider "azurerm" {
  alias           = "vs_professional_sub"
  features {}
  subscription_id = "0e22c153-f2ea-48d7-88b2-584ea3e17673"
}

provider "azurerm" {
  alias           = "vs_professional_sub_2"
  features {}
  subscription_id = "43aae608-0777-4d49-a932-ffc91e5c282e"
}

provider "azurerm" {
  alias           = "vspro_subscription"
  features {}
  subscription_id = "d3ff9a7b-b406-4a90-81d4-ba8528ee310e"
}

provider "azurerm" {
  alias           = "xpe_ams"
  features {}
  subscription_id = "f6c3d24b-5d01-4266-971c-5f596fa78ec1"
}

provider "azurerm" {
  alias           = "xpe_pocxcs"
  features {}
  subscription_id = "19e56997-849b-4e70-b116-d19da1fa159c"
}

provider "azurerm" {
  alias           = "xpe_shared_poc"
  features {}
  subscription_id = "bc444e87-bfcd-4aeb-93f9-9a52b1089062"
}

provider "azurerm" {
  alias           = "xpeappfinprd_xcs"
  features {}
  subscription_id = "001a377b-07aa-466e-9f0b-890b7a511f92"
}

provider "azurerm" {
  alias           = "xpeappfinqa_xcs"
  features {}
  subscription_id = "b896776e-7f3f-4958-866b-c6cb936acd02"
}

provider "azurerm" {
  alias           = "xperhdev_xcs"
  features {}
  subscription_id = "3c600992-d1eb-4443-bb8e-a3d4a667730e"
}

provider "azurerm" {
  alias           = "xperhdmz_xcs"
  features {}
  subscription_id = "268a2f4f-47aa-4dfb-b066-9eedb5f2e4f4"
}

provider "azurerm" {
  alias           = "xperhdrp_xcs"
  features {}
  subscription_id = "614cc18f-8ad8-441f-a545-ae0a5cf5c176"
}

provider "azurerm" {
  alias           = "xperhhub_xcs"
  features {}
  subscription_id = "14b5a06f-ec75-4501-8b07-16ff6838063f"
}

provider "azurerm" {
  alias           = "xperhprd_xcs"
  features {}
  subscription_id = "d3aa3d85-50c2-4d2c-9b0d-c569056c1dac"
}

provider "azurerm" {
  alias           = "xperhqa_xcs"
  features {}
  subscription_id = "d454b38f-b8c0-45d6-945c-2633efd1123a"
}

provider "azurerm" {
  alias           = "xperhsbx_xcs"
  features {}
  subscription_id = "9fca970f-2db0-43ec-85ec-58d1450bb625"
}

provider "azurerm" {
  alias           = "xperhshared_xcs"
  features {}
  subscription_id = "728488ac-97b5-4c60-baa2-1caef72a3467"
}

provider "azurerm" {
  alias           = "xpertal_xcs"
  features {}
  subscription_id = "6d94fbd2-8182-4943-a9b3-53d236df5469"
}

provider "azurerm" {
  alias           = "Xpertal_XCS"
  features {}
  subscription_id = "6d94fbd2-8182-4943-a9b3-53d236df5469"
}

provider "azurerm" {
  alias           = "xpertal_shared_xcs"
  features {}
  subscription_id = "9442ead9-7f87-4f7a-b248-53e511abefd7"
}

provider "azurerm" {
  alias           = "xpertaldc_xcs"
  features {}
  subscription_id = "902313ff-c8ca-46c4-a047-6271ce4dc49a"
}

provider "azurerm" {
  alias           = "xpeseg_xcs"
  features {}
  subscription_id = "5c589577-440f-428c-baeb-bf0999fc3586"
}

provider "azurerm" {
  alias           = "xpeperfiles-xcs"
  features {}
  subscription_id = "e571034b-f6f9-4ed3-afca-61a671ecba1d"
}