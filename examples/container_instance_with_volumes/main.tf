# Ejemplo: Container Instance con Volúmenes Persistentes
# Este ejemplo muestra cómo usar Azure File Share para persistir datos

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
  name     = "rg-container-volumes-example"
  location = "eastus"
}

# Crear Storage Account para Azure Files
resource "azurerm_storage_account" "example" {
  name                     = "stcontainer${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    UDN      = "example"
    OWNER    = "terraform"
    xpeowner = "devops"
    proyecto = "container-examples"
    ambiente = "dev"
  }
}

# Crear Azure File Share
resource "azurerm_storage_share" "example" {
  name                 = "container-data"
  storage_account_name = azurerm_storage_account.example.name
  quota                = 5 # 5 GB
}

# Crear un archivo de ejemplo en el File Share
resource "azurerm_storage_share_file" "example" {
  name             = "config.json"
  storage_share_id = azurerm_storage_share.example.id
  source           = "${path.module}/config.json"

  depends_on = [local_file.config]
}

# Crear archivo de configuración local
resource "local_file" "config" {
  filename = "${path.module}/config.json"
  content = jsonencode({
    app_name    = "example-app"
    environment = "production"
    version     = "1.0.0"
    features = {
      logging_enabled     = true
      metrics_enabled     = true
      debug_mode          = false
      max_connections     = 100
      timeout_seconds     = 30
    }
  })
}

# Desplegar Container Instance con volumen montado
module "container_instance" {
  source = "../../modules/container_instance"

  container_group_name = "ci-app-with-volumes"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  os_type         = "Linux"
  ip_address_type = "Public"
  dns_name_label  = "app-volumes-${random_string.dns_suffix.result}"
  restart_policy  = "Always"

  containers = [{
    name   = "nginx-with-data"
    image  = "nginx:latest"
    cpu    = 1
    memory = 1.5

    ports = [{
      port     = 80
      protocol = "TCP"
    }]

    # Montar volúmenes
    volumes = [
      # Volumen para datos de la aplicación
      {
        name                 = "app-data"
        mount_path           = "/mnt/data"
        read_only            = false
        share_name           = azurerm_storage_share.example.name
        storage_account_name = azurerm_storage_account.example.name
        storage_account_key  = azurerm_storage_account.example.primary_access_key
      },
      # Volumen para configuración (read-only)
      {
        name                 = "app-config"
        mount_path           = "/etc/app"
        read_only            = true
        share_name           = azurerm_storage_share.example.name
        storage_account_name = azurerm_storage_account.example.name
        storage_account_key  = azurerm_storage_account.example.primary_access_key
      }
    ]

    environment_variables = {
      "DATA_PATH"   = "/mnt/data"
      "CONFIG_PATH" = "/etc/app/config.json"
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

# Sufijos aleatorios para nombres únicos
resource "random_string" "storage_suffix" {
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
output "container_url" {
  description = "URL del contenedor"
  value       = "http://${module.container_instance.fqdn}"
}

output "storage_account_name" {
  description = "Nombre del Storage Account"
  value       = azurerm_storage_account.example.name
}

output "file_share_name" {
  description = "Nombre del File Share"
  value       = azurerm_storage_share.example.name
}

output "file_share_url" {
  description = "URL del File Share"
  value       = "https://${azurerm_storage_account.example.name}.file.core.windows.net/${azurerm_storage_share.example.name}"
}

output "access_commands" {
  description = "Comandos para acceder al File Share"
  value = <<-EOT

  # Ver archivos en el File Share
  az storage file list \
    --account-name ${azurerm_storage_account.example.name} \
    --account-key "${azurerm_storage_account.example.primary_access_key}" \
    --share-name ${azurerm_storage_share.example.name}

  # Subir un archivo al File Share
  az storage file upload \
    --account-name ${azurerm_storage_account.example.name} \
    --account-key "${azurerm_storage_account.example.primary_access_key}" \
    --share-name ${azurerm_storage_share.example.name} \
    --source ./myfile.txt \
    --path myfile.txt

  # Descargar un archivo del File Share
  az storage file download \
    --account-name ${azurerm_storage_account.example.name} \
    --account-key "${azurerm_storage_account.example.primary_access_key}" \
    --share-name ${azurerm_storage_share.example.name} \
    --path config.json \
    --dest ./downloaded-config.json

  # Conectar desde un contenedor
  az container exec \
    --name ${module.container_instance.container_group_name} \
    --container-name nginx-with-data \
    --resource-group ${azurerm_resource_group.example.name} \
    --exec-command "/bin/bash"

  # Una vez dentro del contenedor:
  ls -la /mnt/data          # Ver datos
  cat /etc/app/config.json  # Ver configuración
  echo "test" > /mnt/data/test.txt  # Crear archivo

  EOT
  sensitive = true
}

output "mount_info" {
  description = "Información de los volúmenes montados"
  value = {
    app_data = {
      mount_path = "/mnt/data"
      read_only  = false
      purpose    = "Datos persistentes de la aplicación"
    }
    app_config = {
      mount_path = "/etc/app"
      read_only  = true
      purpose    = "Configuración de la aplicación"
    }
  }
}
