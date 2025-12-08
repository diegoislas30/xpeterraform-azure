# Ejemplo: Desplegar Imagen Local (portal_costos_cloud) a Azure
# Este ejemplo crea ACR y despliega tu aplicación Flask desde una imagen local

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

# Variables configurables
variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
  default     = "portal-costos"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# Crear Resource Group
resource "azurerm_resource_group" "app" {
  name     = "rg-${var.app_name}-${var.environment}"
  location = var.location

  tags = {
    UDN      = "portal-costos"
    OWNER    = "diego"
    xpeowner = "diego"
    proyecto = "portal-costos-cloud"
    ambiente = var.environment
  }
}

# Crear Azure Container Registry
module "acr" {
  source = "../../modules/acr"

  acr_name            = "acr${var.app_name}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  sku                 = "Standard"

  # Habilitar admin user para facilitar el push inicial
  # En producción, considera usar Managed Identity
  admin_enabled = true

  tags = {
    UDN      = "portal-costos"
    OWNER    = "diego"
    xpeowner = "diego"
    proyecto = "portal-costos-cloud"
    ambiente = var.environment
  }
}

# Desplegar Container Instance con la aplicación Flask
module "container_instance" {
  source = "../../modules/container_instance"

  container_group_name = "ci-${var.app_name}-${var.environment}"
  resource_group_name  = azurerm_resource_group.app.name
  location             = azurerm_resource_group.app.location

  os_type         = "Linux"
  ip_address_type = "Public"
  dns_name_label  = "${var.app_name}-${var.environment}-${random_string.dns_suffix.result}"
  restart_policy  = "Always"

  containers = [{
    name   = "portal-costos"
    # Esta imagen será actualizada después del push
    image  = "${module.acr.login_server}/portal_costos_cloud:latest"
    cpu    = 2      # Flask app puede necesitar más recursos
    memory = 4      # 4GB para la app

    ports = [{
      port     = 5000  # Puerto de Flask
      protocol = "TCP"
    }]

    environment_variables = {
      "FLASK_ENV"        = var.environment
      "FLASK_APP"        = "app.py"
      "PYTHONUNBUFFERED" = "1"
      # Agrega aquí más variables de entorno que necesite tu app
      # "DATABASE_URL" = "..."
      # "API_KEY" = "..." (mejor usar secure_environment_variables)
    }

    # Para variables sensibles (passwords, API keys, etc)
    # secure_environment_variables = {
    #   "SECRET_KEY" = "tu-secret-key"
    #   "DB_PASSWORD" = "tu-password"
    # }
  }]

  # Credenciales para pull desde ACR
  image_registry_credentials = [{
    server   = module.acr.login_server
    username = module.acr.admin_username
    password = module.acr.admin_password
  }]

  tags = {
    UDN      = "portal-costos"
    OWNER    = "diego"
    xpeowner = "diego"
    proyecto = "portal-costos-cloud"
    ambiente = var.environment
  }

  # Nota: El container fallará hasta que subas la imagen
  # Sigue las instrucciones en el README
}

# Sufijos aleatorios para nombres únicos
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "random_string" "dns_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Outputs
output "acr_login_server" {
  description = "URL del Azure Container Registry"
  value       = module.acr.login_server
}

output "acr_name" {
  description = "Nombre del ACR"
  value       = module.acr.acr_name
}

output "acr_admin_username" {
  description = "Usuario admin del ACR"
  value       = module.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Password admin del ACR"
  value       = module.acr.admin_password
  sensitive   = true
}

output "container_url" {
  description = "URL pública de la aplicación"
  value       = "http://${module.container_instance.fqdn}:5000"
}

output "container_fqdn" {
  description = "FQDN del contenedor"
  value       = module.container_instance.fqdn
}

output "container_ip" {
  description = "IP pública del contenedor"
  value       = module.container_instance.ip_address
}

output "deployment_commands" {
  description = "Comandos para desplegar tu imagen local"
  value = <<-EOT

  ╔═══════════════════════════════════════════════════════════════╗
  ║          PASOS PARA DESPLEGAR TU IMAGEN LOCAL                ║
  ╚═══════════════════════════════════════════════════════════════╝

  1️⃣  OBTENER CREDENCIALES DEL ACR:
  ─────────────────────────────────────────────────────────────────
  terraform output acr_admin_password

  2️⃣  LOGIN AL ACR DESDE DOCKER:
  ─────────────────────────────────────────────────────────────────
  docker login ${module.acr.login_server} \
    --username ${module.acr.admin_username} \
    --password $(terraform output -raw acr_admin_password)

  3️⃣  TAGEAR TU IMAGEN LOCAL:
  ─────────────────────────────────────────────────────────────────
  docker tag portal_costos_cloud-1-portal-costos:latest \
    ${module.acr.login_server}/portal_costos_cloud:latest

  4️⃣  PUSH AL ACR:
  ─────────────────────────────────────────────────────────────────
  docker push ${module.acr.login_server}/portal_costos_cloud:latest

  5️⃣  REINICIAR EL CONTAINER PARA USAR LA NUEVA IMAGEN:
  ─────────────────────────────────────────────────────────────────
  az container restart \
    --name ${module.container_instance.container_group_name} \
    --resource-group ${azurerm_resource_group.app.name}

  6️⃣  VERIFICAR QUE FUNCIONA:
  ─────────────────────────────────────────────────────────────────
  # Ver logs
  az container logs \
    --name ${module.container_instance.container_group_name} \
    --resource-group ${azurerm_resource_group.app.name}

  # Acceder a la app
  curl http://${module.container_instance.fqdn}:5000

  7️⃣  ABRIR EN EL NAVEGADOR:
  ─────────────────────────────────────────────────────────────────
  open http://${module.container_instance.fqdn}:5000

  ╔═══════════════════════════════════════════════════════════════╗
  ║                    ACTUALIZACIONES FUTURAS                    ║
  ╚═══════════════════════════════════════════════════════════════╝

  Para actualizar la aplicación, simplemente:

  docker tag portal_costos_cloud-1-portal-costos:latest \
    ${module.acr.login_server}/portal_costos_cloud:v2

  docker push ${module.acr.login_server}/portal_costos_cloud:v2

  # Actualizar el container para usar :v2
  az container restart \
    --name ${module.container_instance.container_group_name} \
    --resource-group ${azurerm_resource_group.app.name}

  EOT
}

output "monitoring_commands" {
  description = "Comandos para monitorear la aplicación"
  value = <<-EOT

  # Ver logs en tiempo real
  az container attach \
    --name ${module.container_instance.container_group_name} \
    --resource-group ${azurerm_resource_group.app.name}

  # Ver estado del contenedor
  az container show \
    --name ${module.container_instance.container_group_name} \
    --resource-group ${azurerm_resource_group.app.name} \
    --query "{Name:name, State:instanceView.currentState.state, IP:ipAddress.ip, FQDN:ipAddress.fqdn}"

  # Ejecutar comando dentro del contenedor
  az container exec \
    --name ${module.container_instance.container_group_name} \
    --container-name portal-costos \
    --resource-group ${azurerm_resource_group.app.name} \
    --exec-command "/bin/bash"

  EOT
}
