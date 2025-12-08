# Módulo Azure Container Registry (ACR)

Este módulo permite crear y gestionar un Azure Container Registry para almacenar y administrar imágenes de contenedores.

## Características

- ✅ Soporte para todos los SKUs: Basic, Standard, Premium
- ✅ Geo-replicación (Premium)
- ✅ Network rules y private endpoints (Premium)
- ✅ Managed Identity (System/User Assigned)
- ✅ Encriptación con customer-managed keys (Premium)
- ✅ Políticas de retención, trust y quarantine (Premium)
- ✅ Zone redundancy (Premium)
- ✅ Admin user opcional
- ✅ Anonymous pull access
- ✅ Data endpoints dedicados

## Uso Básico

```hcl
module "acr" {
  source = "./modules/acr"

  acr_name            = "mycompanyacr001"
  resource_group_name = "my-rg"
  location            = "eastus"
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    UDN      = "..."
    OWNER    = "..."
    xpeowner = "..."
    proyecto = "..."
    ambiente = "..."
  }
}
```

## Integración con Azure Container Instances

### Opción 1: Usando Admin Credentials (Simple)

```hcl
# 1. Crear ACR
module "acr" {
  source = "./modules/acr"

  acr_name            = "mycompanyacr001"
  resource_group_name = "my-rg"
  location            = "eastus"
  sku                 = "Standard"
  admin_enabled       = true

  tags = var.tags
}

# 2. Crear Container Instance con autenticación ACR
module "container_instance" {
  source = "./modules/container_instance"

  container_group_name = "my-app"
  resource_group_name  = "my-rg"
  location             = "eastus"

  containers = [{
    name   = "nginx"
    image  = "${module.acr.login_server}/nginx:latest"
    cpu    = 1
    memory = 1.5
    ports  = [{
      port     = 80
      protocol = "TCP"
    }]
  }]

  # Credenciales del ACR
  image_registry_credentials = [{
    server   = module.acr.login_server
    username = module.acr.admin_username
    password = module.acr.admin_password
  }]

  tags = var.tags
}
```

### Opción 2: Usando Managed Identity (Recomendado para Producción)

```hcl
# 1. Crear ACR
module "acr" {
  source = "./modules/acr"

  acr_name            = "mycompanyacr001"
  resource_group_name = "my-rg"
  location            = "eastus"
  sku                 = "Standard"
  admin_enabled       = false  # No necesitamos admin user

  tags = var.tags
}

# 2. Crear Container Instance con Managed Identity
module "container_instance" {
  source = "./modules/container_instance"

  container_group_name = "my-app"
  resource_group_name  = "my-rg"
  location             = "eastus"

  containers = [{
    name   = "nginx"
    image  = "${module.acr.login_server}/nginx:latest"
    cpu    = 1
    memory = 1.5
  }]

  # Habilitar System Managed Identity
  identity_type = "SystemAssigned"

  tags = var.tags
}

# 3. Dar permiso al Container Instance para pull de ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.container_instance.identity[0].principal_id
}
```

## Importar Imágenes de Docker Hub a ACR

### Usando Azure CLI

```bash
# Login al ACR
az acr login --name mycompanyacr001

# Importar imagen pública
az acr import \
  --name mycompanyacr001 \
  --source docker.io/library/nginx:latest \
  --image nginx:latest

# Importar imagen privada de Docker Hub
az acr import \
  --name mycompanyacr001 \
  --source docker.io/myusername/private-image:tag \
  --image private-image:tag \
  --username myusername \
  --password mypassword
```

### Usando Docker

```bash
# Login al ACR
az acr login --name mycompanyacr001

# Pull de Docker Hub
docker pull nginx:latest

# Tag para ACR
docker tag nginx:latest mycompanyacr001.azurecr.io/nginx:latest

# Push a ACR
docker push mycompanyacr001.azurecr.io/nginx:latest
```

## Ejemplos de Configuración Avanzada

### Premium con Geo-replicación

```hcl
module "acr_premium" {
  source = "./modules/acr"

  acr_name            = "mycompanyacr001"
  resource_group_name = "my-rg"
  location            = "eastus"
  sku                 = "Premium"

  georeplications = [
    {
      location                = "westus"
      zone_redundancy_enabled = true
    },
    {
      location                = "westeurope"
      zone_redundancy_enabled = true
    }
  ]

  zone_redundancy_enabled = true
  retention_policy_days   = 30

  tags = var.tags
}
```

### Premium con Network Rules

```hcl
module "acr_private" {
  source = "./modules/acr"

  acr_name            = "mycompanyacr001"
  resource_group_name = "my-rg"
  location            = "eastus"
  sku                 = "Premium"

  public_network_access_enabled = false

  network_rule_set = {
    default_action = "Deny"
    ip_rules = [
      "203.0.113.0/24",
      "198.51.100.0/24"
    ]
    virtual_network_subnet_ids = [
      azurerm_subnet.example.id
    ]
  }

  tags = var.tags
}
```

## Variables

Ver `variables.tf` para la lista completa de variables disponibles.

## Outputs

- `acr_id` - ID del Container Registry
- `acr_name` - Nombre del Container Registry
- `login_server` - URL del login server (ej: myacr.azurecr.io)
- `admin_username` - Usuario admin (si está habilitado)
- `admin_password` - Password admin (si está habilitado)
- `identity` - Identity block
- `sku` - SKU del registry

## Notas Importantes

1. **Nombre del ACR**: Debe ser globalmente único y solo contener letras y números
2. **SKU Basic**: Limitado a 10 GiB de storage
3. **SKU Standard**: Hasta 100 GiB de storage
4. **SKU Premium**: Storage ilimitado + geo-replicación + network rules
5. **Admin User**: Útil para desarrollo, pero usar Managed Identity en producción
6. **Rate Limits**: ACR no tiene rate limits como Docker Hub
