# Ejemplo básico de Azure Container Instance
# Este ejemplo despliega un contenedor NGINX público con DNS

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Crear Resource Group
resource "azurerm_resource_group" "example" {
  name     = "rg-container-basic-example"
  location = "eastus"
}

# Desplegar Container Instance con NGINX
module "container_instance" {
  source = "../../modules/container_instance"

  container_group_name = "ci-nginx-basic"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  os_type         = "Linux"
  ip_address_type = "Public"
  dns_name_label  = "nginx-basic-${random_string.dns_suffix.result}"
  restart_policy  = "Always"

  containers = [{
    name   = "nginx"
    image  = "nginx:latest"
    cpu    = 1
    memory = 1.5

    ports = [{
      port     = 80
      protocol = "TCP"
    }]

    environment_variables = {
      "NGINX_PORT" = "80"
    }
  }]

  tags = {
    UDN      = "example"
    OWNER    = "terraform"
    xpeowner = "devops"
    proyecto = "container-examples"
    ambiente = "dev"
  }
}

# Generar sufijo aleatorio para DNS único
resource "random_string" "dns_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Outputs
output "container_url" {
  description = "URL pública del contenedor"
  value       = "http://${module.container_instance.fqdn}"
}

output "container_ip" {
  description = "IP pública del contenedor"
  value       = module.container_instance.ip_address
}
