# Ejemplo Avanzado - Múltiples contenedores con sidecar pattern
# Este ejemplo despliega una aplicación web con un sidecar de logging

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
  name     = "rg-container-advanced-example"
  location = "eastus"
}

# Desplegar Container Group con múltiples contenedores
module "container_instance" {
  source = "../../modules/container_instance"

  container_group_name = "ci-webapp-with-sidecar"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  os_type         = "Linux"
  ip_address_type = "Public"
  dns_name_label  = "webapp-advanced-${random_string.dns_suffix.result}"
  restart_policy  = "Always"

  containers = [
    # Contenedor principal: Aplicación web
    {
      name   = "webapp"
      image  = "nginx:latest"
      cpu    = 1
      memory = 1.5

      ports = [{
        port     = 80
        protocol = "TCP"
      }]

      environment_variables = {
        "APP_ENV"     = "production"
        "APP_VERSION" = "1.0.0"
        "LOG_LEVEL"   = "info"
      }
    },

    # Sidecar: Agente de monitoreo/logging
    {
      name   = "log-agent"
      image  = "busybox:latest"
      cpu    = 0.5
      memory = 0.5

      # Comando para simular un agente de logs
      environment_variables = {
        "MONITOR_INTERVAL" = "60"
        "LOG_DESTINATION"  = "azure-monitor"
      }
    },

    # Sidecar: Proxy/Cache
    {
      name   = "redis-cache"
      image  = "redis:alpine"
      cpu    = 0.5
      memory = 0.5

      ports = [{
        port     = 6379
        protocol = "TCP"
      }]

      environment_variables = {
        "REDIS_MAXMEMORY" = "100mb"
      }
    }
  ]

  tags = {
    UDN      = "example"
    OWNER    = "terraform"
    xpeowner = "devops"
    proyecto = "container-examples"
    ambiente = "production"
  }
}

# Generar sufijo aleatorio para DNS único
resource "random_string" "dns_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Outputs
output "webapp_url" {
  description = "URL de la aplicación web"
  value       = "http://${module.container_instance.fqdn}"
}

output "container_ip" {
  description = "IP pública del container group"
  value       = module.container_instance.ip_address
}

output "container_id" {
  description = "ID del container group"
  value       = module.container_instance.container_group_id
}

output "containers_info" {
  description = "Información de los contenedores"
  value = {
    webapp = {
      image  = "nginx:latest"
      cpu    = "1.0"
      memory = "1.5 GB"
      port   = "80"
    }
    log_agent = {
      image  = "busybox:latest"
      cpu    = "0.5"
      memory = "0.5 GB"
      role   = "monitoring/logging sidecar"
    }
    redis_cache = {
      image  = "redis:alpine"
      cpu    = "0.5"
      memory = "0.5 GB"
      port   = "6379"
      role   = "caching sidecar"
    }
  }
}

output "total_resources" {
  description = "Total de recursos asignados"
  value = {
    total_cpu    = "2.0 vCPU"
    total_memory = "2.5 GB"
    containers   = 3
  }
}

output "monitoring_commands" {
  description = "Comandos útiles para monitoreo"
  value = <<-EOT

  # Ver logs del contenedor principal
  az container logs --name ${module.container_instance.container_group_name} \
    --container-name webapp \
    --resource-group ${azurerm_resource_group.example.name}

  # Ver logs del sidecar de monitoring
  az container logs --name ${module.container_instance.container_group_name} \
    --container-name log-agent \
    --resource-group ${azurerm_resource_group.example.name}

  # Ver logs de Redis
  az container logs --name ${module.container_instance.container_group_name} \
    --container-name redis-cache \
    --resource-group ${azurerm_resource_group.example.name}

  # Ejecutar comando en un contenedor
  az container exec --name ${module.container_instance.container_group_name} \
    --container-name webapp \
    --resource-group ${azurerm_resource_group.example.name} \
    --exec-command "/bin/bash"

  # Ver estado de todos los contenedores
  az container show --name ${module.container_instance.container_group_name} \
    --resource-group ${azurerm_resource_group.example.name} \
    --query "containers[].{Name:name, State:instanceView.currentState.state, CPU:resources.requests.cpu, Memory:resources.requests.memoryInGb}"

  EOT
}
