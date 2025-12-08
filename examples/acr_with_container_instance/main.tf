# Ejemplo: ACR + Container Instance con Managed Identity
# Este ejemplo muestra cómo usar imágenes privadas desde ACR usando Managed Identity (Recomendado)

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
  name     = "rg-acr-aci-example"
  location = "eastus"
}

# Crear Azure Container Registry
module "acr" {
  source = "../../modules/acr"

  acr_name            = "acr${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"

  # No necesitamos admin user con Managed Identity
  admin_enabled = false

  tags = {
    UDN      = "example"
    OWNER    = "terraform"
    xpeowner = "devops"
    proyecto = "container-examples"
    ambiente = "dev"
  }
}

# Crear Container Instance con System Managed Identity
module "container_instance" {
  source = "../../modules/container_instance"

  container_group_name = "ci-app-from-acr"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  os_type         = "Linux"
  ip_address_type = "Public"
  dns_name_label  = "app-acr-${random_string.dns_suffix.result}"
  restart_policy  = "Always"

  # Habilitar System Managed Identity
  identity_type = "SystemAssigned"

  containers = [{
    name   = "nginx"
    # Imagen desde ACR (después de importarla)
    image  = "${module.acr.login_server}/nginx:latest"
    cpu    = 1
    memory = 1.5

    ports = [{
      port     = 80
      protocol = "TCP"
    }]
  }]

  tags = {
    UDN      = "example"
    OWNER    = "terraform"
    xpeowner = "devops"
    proyecto = "container-examples"
    ambiente = "dev"
  }
}

# Dar permiso al Container Instance para hacer pull desde ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.container_instance.identity[0].principal_id
}

# Sufijos aleatorios para nombres únicos
resource "random_string" "acr_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "random_string" "dns_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Outputs
output "acr_login_server" {
  description = "URL del Azure Container Registry"
  value       = module.acr.login_server
}

output "import_command" {
  description = "Comando para importar una imagen de Docker Hub"
  value       = "az acr import --name ${module.acr.acr_name} --source docker.io/library/nginx:latest --image nginx:latest"
}

output "container_url" {
  description = "URL pública del contenedor"
  value       = "http://${module.container_instance.fqdn}"
}

output "next_steps" {
  description = "Próximos pasos"
  value = <<-EOT

  1. Login al ACR:
     az acr login --name ${module.acr.acr_name}

  2. Importar imagen desde Docker Hub:
     az acr import --name ${module.acr.acr_name} --source docker.io/library/nginx:latest --image nginx:latest

  3. O construir y subir tu propia imagen:
     docker build -t ${module.acr.login_server}/myapp:v1 .
     docker push ${module.acr.login_server}/myapp:v1

  4. Actualizar el container group para reiniciarlo:
     az container restart --name ${module.container_instance.container_group_name} --resource-group ${azurerm_resource_group.example.name}

  5. Acceder a la aplicación:
     curl http://${module.container_instance.fqdn}

  EOT
}
