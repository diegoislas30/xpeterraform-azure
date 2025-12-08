# Ejemplo Avanzado - Múltiples Contenedores con Sidecar Pattern

Este ejemplo demuestra el uso de múltiples contenedores en un Container Group usando el **sidecar pattern**.

## ¿Qué es el Sidecar Pattern?

El sidecar pattern ejecuta múltiples contenedores en el mismo pod/container group que:
- Comparten el mismo ciclo de vida
- Comparten la misma red (localhost)
- Comparten el mismo almacenamiento
- Cada contenedor tiene recursos dedicados

## Arquitectura de este ejemplo

```
┌─────────────────────────────────────────────┐
│      Container Group (Shared Network)      │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │   webapp     │  │  log-agent   │       │
│  │  nginx:latest│  │busybox:latest│       │
│  │  CPU: 1.0    │  │  CPU: 0.5    │       │
│  │  RAM: 1.5GB  │  │  RAM: 0.5GB  │       │
│  │  Port: 80    │  │  (sidecar)   │       │
│  └──────────────┘  └──────────────┘       │
│                                             │
│         ┌──────────────┐                   │
│         │ redis-cache  │                   │
│         │ redis:alpine │                   │
│         │  CPU: 0.5    │                   │
│         │  RAM: 0.5GB  │                   │
│         │  Port: 6379  │                   │
│         │  (sidecar)   │                   │
│         └──────────────┘                   │
│                                             │
│  Total: 2.0 vCPU, 2.5GB RAM               │
└─────────────────────────────────────────────┘
```

## Casos de uso del Sidecar Pattern

### 1. **Logging/Monitoring Sidecars**
- Fluentd, Filebeat, Datadog agent
- Recolectan logs de la app principal
- Envían métricas a sistemas externos

### 2. **Proxy Sidecars**
- Envoy, NGINX
- Service mesh proxies
- TLS termination

### 3. **Cache Sidecars**
- Redis, Memcached
- Cache local para la app
- Reduce latencia

### 4. **Data Sync Sidecars**
- Sincronización de archivos
- Backup continuo
- Git sync

## ¿Qué hace este ejemplo?

- **webapp**: Contenedor principal (NGINX) que sirve la aplicación
- **log-agent**: Sidecar que simula un agente de logs/monitoreo
- **redis-cache**: Sidecar que provee cache local

## Uso

```bash
# Inicializar
terraform init

# Aplicar
terraform apply

# Ver información de los contenedores
terraform output containers_info

# Ver recursos totales
terraform output total_resources

# Ver comandos de monitoreo
terraform output monitoring_commands
```

## Verificar el despliegue

### Ver logs de cada contenedor

```bash
# Logs del webapp
az container logs \
  --name ci-webapp-with-sidecar \
  --container-name webapp \
  --resource-group rg-container-advanced-example

# Logs del log-agent
az container logs \
  --name ci-webapp-with-sidecar \
  --container-name log-agent \
  --resource-group rg-container-advanced-example

# Logs del redis
az container logs \
  --name ci-webapp-with-sidecar \
  --container-name redis-cache \
  --resource-group rg-container-advanced-example
```

### Ejecutar comandos en los contenedores

```bash
# Entrar al webapp
az container exec \
  --name ci-webapp-with-sidecar \
  --container-name webapp \
  --resource-group rg-container-advanced-example \
  --exec-command "/bin/bash"

# Desde dentro del webapp, puedes acceder a Redis en localhost:
curl localhost:6379
```

### Ver estado de todos los contenedores

```bash
az container show \
  --name ci-webapp-with-sidecar \
  --resource-group rg-container-advanced-example \
  --query "containers[].{Name:name, State:instanceView.currentState.state}"
```

## Comunicación entre contenedores

Todos los contenedores en el mismo Container Group comparten:

**Red**: Se comunican via `localhost`
```bash
# Desde webapp puedes acceder a Redis:
redis-cli -h localhost -p 6379

# O desde tu aplicación:
REDIS_URL=redis://localhost:6379
```

**Volúmenes**: Pueden compartir el mismo volumen
```hcl
volumes = [{
  name       = "shared-logs"
  mount_path = "/var/log/app"
  # Mismo volumen montado en múltiples contenedores
}]
```

## Ejemplo de aplicación real

```hcl
containers = [
  # App principal
  {
    name   = "nodejs-app"
    image  = "myacr.azurecr.io/myapp:v1"
    cpu    = 2
    memory = 4
    ports  = [{ port = 3000 }]
    environment_variables = {
      REDIS_HOST = "localhost"
      REDIS_PORT = "6379"
    }
  },
  # Cache
  {
    name   = "redis"
    image  = "redis:alpine"
    cpu    = 0.5
    memory = 1
    ports  = [{ port = 6379 }]
  },
  # Monitoring
  {
    name   = "prometheus-exporter"
    image  = "prom/node-exporter"
    cpu    = 0.5
    memory = 0.5
    ports  = [{ port = 9100 }]
  }
]
```

## Ventajas del Sidecar Pattern

✅ **Separación de responsabilidades**: Cada contenedor hace una cosa
✅ **Reutilización**: Los sidecars son reutilizables
✅ **Actualizaciones independientes**: Actualiza sidecars sin tocar la app
✅ **Red compartida**: Comunicación ultra-rápida via localhost
✅ **Simplicidad**: No necesitas service mesh complejo

## Desventajas

⚠️ **Recursos**: Cada sidecar consume CPU/RAM adicional
⚠️ **Complejidad**: Más contenedores = más cosas que monitorear
⚠️ **Costo**: Pagas por todos los contenedores

## Costo estimado

- **webapp**: 1 vCPU, 1.5GB = ~$32/mes
- **log-agent**: 0.5 vCPU, 0.5GB = ~$11/mes
- **redis-cache**: 0.5 vCPU, 0.5GB = ~$11/mes
- **Total**: ~$54/mes

## Limpiar recursos

```bash
terraform destroy
```

## Próximos pasos

- Ver `../container_instance_with_volumes/` para persistencia de datos
- Ver `../acr_with_container_instance/` para usar imágenes privadas
