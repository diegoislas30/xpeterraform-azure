# Módulo Azure Container Instances (ACI)

Este módulo permite crear y gestionar Azure Container Instances para ejecutar contenedores sin necesidad de administrar infraestructura.

## Características

- ✅ Soporte para múltiples contenedores en un Container Group
- ✅ Configuración de puertos y protocolos (TCP/UDP)
- ✅ Variables de entorno (normales y seguras)
- ✅ Volúmenes de Azure File Share
- ✅ Managed Identity (System/User Assigned)
- ✅ Credenciales de image registry para imágenes privadas
- ✅ Configuración DNS personalizada
- ✅ IPs públicas/privadas con DNS label
- ✅ Políticas de reinicio configurables (Always/Never/OnFailure)

## Uso Básico

```hcl
module "container_instance" {
  source = "./modules/container_instance"

  container_group_name = "my-app"
  resource_group_name  = "my-rg"
  location             = "eastus"

  os_type         = "Linux"
  ip_address_type = "Public"
  dns_name_label  = "myapp-unique"
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
  }]

  tags = {
    UDN      = "..."
    OWNER    = "..."
    xpeowner = "..."
    proyecto = "..."
    ambiente = "..."
  }
}
```

## Ejemplos de Uso

### 1. Contenedor Simple

```hcl
module "simple_container" {
  source = "./modules/container_instance"

  container_group_name = "nginx-simple"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  containers = [{
    name   = "nginx"
    image  = "nginx:latest"
    cpu    = 1
    memory = 1.5
    ports  = [{ port = 80 }]
  }]

  tags = var.tags
}
```

### 2. Con Variables de Entorno

```hcl
module "app_with_env" {
  source = "./modules/container_instance"

  container_group_name = "myapp"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  containers = [{
    name   = "app"
    image  = "myapp:v1"
    cpu    = 2
    memory = 4

    ports = [{ port = 3000 }]

    # Variables de entorno normales
    environment_variables = {
      "NODE_ENV"    = "production"
      "API_URL"     = "https://api.example.com"
      "LOG_LEVEL"   = "info"
    }

    # Variables de entorno seguras (passwords, secrets)
    secure_environment_variables = {
      "DATABASE_PASSWORD" = var.db_password
      "API_KEY"          = var.api_key
    }
  }]

  tags = var.tags
}
```

### 3. Con Imágenes Privadas desde ACR

```hcl
module "acr_container" {
  source = "./modules/container_instance"

  container_group_name = "private-app"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  containers = [{
    name   = "myapp"
    image  = "myacr.azurecr.io/myapp:v1"
    cpu    = 2
    memory = 4
    ports  = [{ port = 8080 }]
  }]

  # Credenciales para ACR
  image_registry_credentials = [{
    server   = "myacr.azurecr.io"
    username = data.azurerm_container_registry.acr.admin_username
    password = data.azurerm_container_registry.acr.admin_password
  }]

  tags = var.tags
}
```

### 4. Con Managed Identity (Recomendado)

```hcl
module "container_with_identity" {
  source = "./modules/container_instance"

  container_group_name = "app-with-identity"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  # Habilitar System Managed Identity
  identity_type = "SystemAssigned"

  containers = [{
    name   = "app"
    image  = "myacr.azurecr.io/myapp:v1"
    cpu    = 2
    memory = 4
  }]

  tags = var.tags
}

# Dar permisos para pull desde ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.container_with_identity.identity[0].principal_id
}
```

### 5. Múltiples Contenedores (Sidecar Pattern)

```hcl
module "multi_container" {
  source = "./modules/container_instance"

  container_group_name = "app-with-sidecars"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  containers = [
    # Contenedor principal
    {
      name   = "webapp"
      image  = "nginx:latest"
      cpu    = 1
      memory = 1.5
      ports  = [{ port = 80 }]
    },
    # Sidecar: Redis cache
    {
      name   = "redis"
      image  = "redis:alpine"
      cpu    = 0.5
      memory = 0.5
      ports  = [{ port = 6379 }]
    },
    # Sidecar: Log agent
    {
      name   = "fluentd"
      image  = "fluentd:latest"
      cpu    = 0.5
      memory = 0.5
    }
  ]

  tags = var.tags
}

# Los contenedores se comunican via localhost:
# webapp puede acceder a Redis en: localhost:6379
```

### 6. Con Volúmenes Persistentes

```hcl
resource "azurerm_storage_account" "storage" {
  name                     = "mystorageaccount"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 10
}

module "container_with_volume" {
  source = "./modules/container_instance"

  container_group_name = "app-with-storage"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  containers = [{
    name   = "app"
    image  = "myapp:v1"
    cpu    = 2
    memory = 4

    # Montar Azure File Share
    volumes = [{
      name                 = "app-data"
      mount_path           = "/data"
      read_only            = false
      share_name           = azurerm_storage_share.share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }]
  }]

  tags = var.tags
}
```

### 7. Con DNS Personalizado

```hcl
module "container_custom_dns" {
  source = "./modules/container_instance"

  container_group_name = "app-custom-dns"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  # DNS servers personalizados
  dns_servers = [
    "8.8.8.8",
    "8.8.4.4"
  ]

  containers = [{
    name   = "app"
    image  = "myapp:v1"
    cpu    = 1
    memory = 2
  }]

  tags = var.tags
}
```

### 8. Con Múltiples Puertos

```hcl
module "multi_port_container" {
  source = "./modules/container_instance"

  container_group_name = "app-multi-port"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  containers = [{
    name   = "app"
    image  = "myapp:v1"
    cpu    = 2
    memory = 4

    # Múltiples puertos
    ports = [
      { port = 80,   protocol = "TCP" },  # HTTP
      { port = 443,  protocol = "TCP" },  # HTTPS
      { port = 8080, protocol = "TCP" },  # Admin
      { port = 9090, protocol = "TCP" }   # Metrics
    ]
  }]

  tags = var.tags
}
```

### 9. IP Privada (VNet Integration)

```hcl
module "private_container" {
  source = "./modules/container_instance"

  container_group_name = "private-app"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  ip_address_type = "Private"
  # Nota: Requiere subnet_ids (no implementado en el módulo base)
  # Para IP privada con VNet, considera extender el módulo

  containers = [{
    name   = "app"
    image  = "myapp:v1"
    cpu    = 1
    memory = 2
  }]

  tags = var.tags
}
```

### 10. Política de Reinicio para Jobs

```hcl
module "batch_job" {
  source = "./modules/container_instance"

  container_group_name = "batch-processor"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location

  # Solo reiniciar en caso de fallo
  restart_policy = "OnFailure"

  containers = [{
    name   = "processor"
    image  = "mybatchjob:v1"
    cpu    = 4
    memory = 8

    environment_variables = {
      "JOB_TYPE" = "data-processing"
    }
  }]

  tags = var.tags
}
```

## Variables

| Nombre | Tipo | Descripción | Requerido | Default |
|--------|------|-------------|-----------|---------|
| `container_group_name` | string | Nombre del Container Group | Sí | - |
| `resource_group_name` | string | Nombre del Resource Group | Sí | - |
| `location` | string | Ubicación de Azure | Sí | - |
| `os_type` | string | Sistema operativo (Linux/Windows) | No | "Linux" |
| `dns_name_label` | string | DNS label para IP pública | No | null |
| `ip_address_type` | string | Tipo de IP (Public/Private/None) | No | "Public" |
| `restart_policy` | string | Política de reinicio (Always/Never/OnFailure) | No | "Always" |
| `containers` | list(object) | Lista de contenedores | Sí | - |
| `identity_type` | string | Tipo de Managed Identity | No | null |
| `identity_ids` | list(string) | IDs de User Assigned Identity | No | [] |
| `image_registry_credentials` | list(object) | Credenciales para registros privados | No | [] |
| `dns_servers` | list(string) | Servidores DNS personalizados | No | [] |
| `tags` | object | Tags para los recursos | Sí | - |

### Estructura del objeto `containers`

```hcl
containers = [{
  name   = string           # Nombre del contenedor (requerido)
  image  = string           # Imagen Docker (requerido)
  cpu    = number           # vCPUs (requerido)
  memory = number           # GB de RAM (requerido)

  ports = optional([{       # Puertos a exponer
    port     = number
    protocol = optional(string) # "TCP" o "UDP"
  }])

  environment_variables = optional(map(string))        # Variables de entorno
  secure_environment_variables = optional(map(string)) # Variables seguras

  volumes = optional([{     # Volúmenes a montar
    name                 = string
    mount_path           = string
    read_only            = optional(bool)
    share_name           = optional(string)
    storage_account_name = optional(string)
    storage_account_key  = optional(string)
  }])
}]
```

## Outputs

| Nombre | Descripción |
|--------|-------------|
| `container_group_id` | ID del Container Group |
| `container_group_name` | Nombre del Container Group |
| `ip_address` | IP pública del Container Group |
| `fqdn` | FQDN del Container Group |
| `identity` | Identity block del Container Group |

## Límites y Restricciones

### Por Container Group (Linux)

| Recurso | Límite |
|---------|--------|
| vCPUs máximas | 4 |
| Memoria máxima | 16 GB |
| Volúmenes | 20 |
| Puertos | 60 |

### Por Container Group (Windows)

| Recurso | Límite |
|---------|--------|
| vCPUs máximas | 4 |
| Memoria máxima | 16 GB |

## Consideraciones de Costos

Los costos de ACI se basan en:
- **vCPUs**: ~$0.0000125/segundo (~$32/mes por vCPU)
- **Memoria**: ~$0.0000014/GB/segundo (~$3.60/mes por GB)

**Ejemplos:**

| Configuración | Costo/mes (24/7) |
|---------------|------------------|
| 0.5 vCPU, 0.5GB | ~$17 |
| 1 vCPU, 1.5GB | ~$32 |
| 2 vCPU, 4GB | ~$85 |
| 4 vCPU, 16GB | ~$187 |

**Tips para ahorrar:**
- Usa `restart_policy = "OnFailure"` para jobs batch
- Apaga contenedores cuando no se usen
- Optimiza el tamaño de las imágenes
- Usa resources solo lo necesario

## Mejores Prácticas

### 1. Seguridad

```hcl
# ✅ Bueno: Usar Managed Identity
identity_type = "SystemAssigned"

# ❌ Malo: Hardcodear credenciales
environment_variables = {
  PASSWORD = "mi-password-123"
}

# ✅ Bueno: Usar secure_environment_variables
secure_environment_variables = {
  PASSWORD = var.db_password
}
```

### 2. Resources

```hcl
# ✅ Bueno: Resources apropiados
cpu    = 1
memory = 2

# ❌ Malo: Sobre-provisionar
cpu    = 4
memory = 16  # Para una app simple
```

### 3. Restart Policy

```hcl
# ✅ Bueno: Para servicios web
restart_policy = "Always"

# ✅ Bueno: Para jobs batch
restart_policy = "OnFailure"

# ❌ Malo: Never para servicios web
restart_policy = "Never"
```

### 4. Health Checks

Implementa health checks en tu aplicación:

```dockerfile
# En tu Dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:5000/health || exit 1
```

### 5. Logging

```hcl
# La app debe loggear a stdout/stderr
# Azure captura estos logs automáticamente
environment_variables = {
  LOG_LEVEL = "info"
  JSON_LOGS = "true"  # Para mejor parsing
}
```

## Comandos Útiles de Azure CLI

### Ver logs

```bash
az container logs \
  --name <container-group-name> \
  --resource-group <rg-name> \
  --container-name <container-name>
```

### Logs en tiempo real

```bash
az container attach \
  --name <container-group-name> \
  --resource-group <rg-name>
```

### Ver estado

```bash
az container show \
  --name <container-group-name> \
  --resource-group <rg-name> \
  --query "{State:instanceView.state, IP:ipAddress.ip, FQDN:ipAddress.fqdn}"
```

### Reiniciar

```bash
az container restart \
  --name <container-group-name> \
  --resource-group <rg-name>
```

### Ejecutar comando

```bash
az container exec \
  --name <container-group-name> \
  --container-name <container-name> \
  --resource-group <rg-name> \
  --exec-command "/bin/bash"
```

### Ver eventos

```bash
az container show \
  --name <container-group-name> \
  --resource-group <rg-name> \
  --query "containers[0].instanceView.events"
```

## Troubleshooting

### Container no inicia

```bash
# Ver eventos
az container show --name <name> --resource-group <rg> \
  --query "containers[0].instanceView.events"

# Ver logs
az container logs --name <name> --resource-group <rg>
```

### Error "ImagePullBackOff"

- Verifica que la imagen existe
- Verifica credenciales de registry
- Verifica conectividad de red

### Container se reinicia constantemente

- Revisa logs: `az container logs`
- Verifica que la app no se cierra inmediatamente
- Asegúrate que la app escucha en 0.0.0.0, no en localhost

### Performance issues

- Incrementa CPU/memoria
- Optimiza la imagen Docker
- Considera usar Premium storage para volúmenes

## Comparación: ACI vs AKS

| Característica | ACI | AKS |
|----------------|-----|-----|
| **Complejidad** | Baja | Alta |
| **Costo** | Pago por uso | Mínimo ~$70/mes |
| **Scaling** | Manual | Auto-scaling |
| **Networking** | Básico | Avanzado |
| **Ideal para** | Apps simples, jobs | Microservicios complejos |
| **Tiempo setup** | Minutos | Horas |

**Usa ACI si:**
- App simple o job batch
- No necesitas auto-scaling
- Quieres simplicidad
- Costo predecible

**Usa AKS si:**
- Microservicios complejos
- Necesitas auto-scaling
- Service mesh, ingress complejo
- Múltiples ambientes

## Recursos Adicionales

- [Documentación de Azure Container Instances](https://learn.microsoft.com/azure/container-instances/)
- [Ejemplos de uso](../../examples/)
- [Precios de ACI](https://azure.microsoft.com/pricing/details/container-instances/)
- [Límites y cuotas](https://learn.microsoft.com/azure/container-instances/container-instances-quotas)

## Ejemplos Completos

Ver el directorio `examples/` para implementaciones completas:
- [Ejemplo básico](../../examples/container_instance_basic/)
- [Con ACR](../../examples/acr_with_container_instance/)
- [Múltiples contenedores](../../examples/container_instance_advanced/)
- [Con volúmenes](../../examples/container_instance_with_volumes/)
- [Deploy imagen local](../../examples/deploy_local_image/)
