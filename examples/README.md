# Ejemplos de Uso - Azure Container Modules

Esta carpeta contiene ejemplos prácticos de cómo usar los módulos de Azure Container Registry y Container Instances.

## 📁 Ejemplos Disponibles

### 1. [Desplegar Imagen Local](./deploy_local_image/) ⭐ NUEVO

**Nivel**: Principiante 🟢

Despliega tu propia imagen Docker local a Azure.

**Caso de uso real:**
- Ya tienes una app corriendo en Docker localmente
- Quieres moverla a la nube sin cambios
- Incluye script automatizado de deployment

**Aprenderás:**
- Subir imagen local a Azure Container Registry
- Desplegar desde ACR a Container Instances
- Automatizar con script bash
- Actualizar tu app en producción

**Tiempo**: ~10 minutos (con script automatizado)

```bash
cd deploy_local_image
chmod +x deploy.sh
./deploy.sh full
```

**Ver**: [Quick Start Guide](./deploy_local_image/QUICKSTART.md)

---

### 2. [Container Instance Básico](./container_instance_basic/)

**Nivel**: Principiante 🟢

Despliega un contenedor NGINX simple con acceso público.

**Aprenderás:**
- Desplegar tu primer contenedor en Azure
- Configurar DNS y acceso público
- Exponer puertos
- Variables de entorno

**Tiempo**: ~5 minutos

```bash
cd container_instance_basic
terraform init && terraform apply
```

---

### 3. [ACR + Container Instance](./acr_with_container_instance/)

**Nivel**: Intermedio 🟡

Crea un Container Registry privado e integra con Container Instances usando Managed Identity.

**Aprenderás:**
- Crear Azure Container Registry
- Importar imágenes desde Docker Hub
- Usar Managed Identity para autenticación
- Roles y permisos (AcrPull)
- Best practices de seguridad

**Tiempo**: ~10 minutos

```bash
cd acr_with_container_instance
terraform init && terraform apply
```

**Después del despliegue:**
```bash
# Importar imagen
az acr import \
  --name <acr-name> \
  --source docker.io/library/nginx:latest \
  --image nginx:latest
```

---

### 4. [Múltiples Contenedores - Sidecar Pattern](./container_instance_advanced/)

**Nivel**: Avanzado 🔴

Despliega múltiples contenedores en un Container Group usando el sidecar pattern.

**Aprenderás:**
- Sidecar pattern (webapp + logging + cache)
- Comunicación entre contenedores (localhost)
- Asignación de recursos por contenedor
- Casos de uso reales (monitoring, caching, proxies)

**Tiempo**: ~10 minutos

**Arquitectura:**
```
Container Group
├─ webapp (nginx) - 1 vCPU, 1.5GB
├─ log-agent (busybox) - 0.5 vCPU, 0.5GB
└─ redis-cache (redis) - 0.5 vCPU, 0.5GB
```

```bash
cd container_instance_advanced
terraform init && terraform apply
```

---

### 5. [Volúmenes Persistentes](./container_instance_with_volumes/)

**Nivel**: Intermedio 🟡

Usa Azure File Share para persistir datos entre reinicios de contenedores.

**Aprenderás:**
- Montar Azure File Share en contenedores
- Volúmenes read-write vs read-only
- Acceder a archivos desde Azure Portal/CLI
- Montar localmente en tu PC
- Backup y recuperación

**Tiempo**: ~15 minutos

```bash
cd container_instance_with_volumes
terraform init && terraform apply
```

---

## 🚀 Guía Rápida

### Prerrequisitos

1. **Azure CLI** instalado y autenticado:
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Terraform** instalado (v1.0+):
   ```bash
   terraform version
   ```

3. **Permisos en Azure**:
   - Contributor role en la subscription

### Ejecutar un ejemplo

```bash
# 1. Elegir un ejemplo
cd <ejemplo-nombre>

# 2. Inicializar Terraform
terraform init

# 3. Ver el plan (opcional)
terraform plan

# 4. Aplicar
terraform apply

# 5. Ver outputs
terraform output

# 6. Limpiar (cuando termines)
terraform destroy
```

## 📊 Comparación de Ejemplos

| Ejemplo | Complejidad | Tiempo | Costo/mes | Casos de Uso |
|---------|-------------|--------|-----------|--------------|
| **Imagen Local** ⭐ | 🟢 Fácil | 10 min | ~$105 | Tu app local → Azure |
| **Básico** | 🟢 Fácil | 5 min | ~$32 | Aprender ACI, demos rápidas |
| **ACR + ACI** | 🟡 Medio | 10 min | ~$37 | Imágenes privadas, producción |
| **Múltiples** | 🔴 Avanzado | 10 min | ~$54 | Microservicios, sidecars |
| **Volúmenes** | 🟡 Medio | 15 min | ~$32 | Persistencia, databases |

## 🎯 Flujo de Aprendizaje Recomendado

```
1. Básico
   ↓
   Entiendes: Contenedores, DNS, puertos
   ↓
2. ACR + ACI
   ↓
   Entiendes: Registries, seguridad, managed identity
   ↓
3. Volúmenes
   ↓
   Entiendes: Persistencia, storage
   ↓
4. Múltiples Contenedores
   ↓
   Entiendes: Arquitecturas complejas, sidecars
```

## 💡 Escenarios por Caso de Uso

### Ya tengo una app corriendo en Docker localmente ⭐
→ Usa **Desplegar Imagen Local**

### Quiero desplegar una app simple
→ Usa **Container Instance Básico**

### Necesito imágenes privadas
→ Usa **ACR + Container Instance**

### Mi app necesita cache/monitoring/proxy
→ Usa **Múltiples Contenedores**

### Necesito guardar datos (DB, uploads, logs)
→ Usa **Volúmenes Persistentes**

### Necesito todo lo anterior
→ Combina los módulos (ver ejemplo abajo)

## 🔧 Ejemplo Completo Combinado

```hcl
# Production-ready setup
module "acr" {
  source = "../modules/acr"
  sku    = "Premium"
  georeplications = [...]
}

module "container" {
  source = "../modules/container_instance"

  # Managed Identity
  identity_type = "SystemAssigned"

  # Múltiples contenedores
  containers = [
    {
      name  = "webapp"
      image = "${module.acr.login_server}/myapp:v1"
      # Con volumen persistente
      volumes = [{
        name       = "app-data"
        mount_path = "/data"
        share_name = azurerm_storage_share.data.name
        ...
      }]
    },
    {
      name  = "redis"
      image = "redis:alpine"
    }
  ]

  # Credenciales para ACR
  image_registry_credentials = [...]
}
```

## 📖 Conceptos Importantes

### Container Group vs Container
- **Container Group**: Equivalente a un "Pod" de Kubernetes
- **Container**: Contenedor individual dentro del grupo
- Los contenedores en el mismo grupo comparten:
  - Red (se comunican via localhost)
  - Ciclo de vida (inician/paran juntos)
  - Volúmenes (pueden compartir storage)

### SKUs de ACR

| SKU | Storage | Bandwidth | Geo-replication | Webhooks |
|-----|---------|-----------|-----------------|----------|
| **Basic** | 10 GB | 10 GB/día | ❌ | 2 |
| **Standard** | 100 GB | 100 GB/día | ❌ | 10 |
| **Premium** | Ilimitado | Ilimitado | ✅ | 500 |

### Tipos de IP

- **Public**: Acceso desde internet con IP pública
- **Private**: Solo desde VNet (requiere VNet integration)
- **None**: Sin conectividad de red

## 🛠️ Comandos Útiles

### Ver logs de un contenedor
```bash
az container logs \
  --name <container-group-name> \
  --container-name <container-name> \
  --resource-group <rg-name>
```

### Ejecutar comandos en un contenedor
```bash
az container exec \
  --name <container-group-name> \
  --container-name <container-name> \
  --resource-group <rg-name> \
  --exec-command "/bin/bash"
```

### Ver estado de contenedores
```bash
az container show \
  --name <container-group-name> \
  --resource-group <rg-name> \
  --query "containers[].{Name:name, State:instanceView.currentState.state}"
```

### Reiniciar un container group
```bash
az container restart \
  --name <container-group-name> \
  --resource-group <rg-name>
```

### Listar imágenes en ACR
```bash
az acr repository list --name <acr-name>
```

### Importar imagen desde Docker Hub
```bash
az acr import \
  --name <acr-name> \
  --source docker.io/library/<image>:<tag> \
  --image <image>:<tag>
```

## 💰 Estimación de Costos

### Container Instance (por mes, 24/7)
- 1 vCPU, 1 GB RAM: ~$21/mes
- 1 vCPU, 1.5 GB RAM: ~$32/mes
- 2 vCPU, 4 GB RAM: ~$85/mes

**Tip**: Usa restart_policy = "OnFailure" para apps batch y reduce costos

### Azure Container Registry
- Basic: ~$5/mes (10 GB storage)
- Standard: ~$20/mes (100 GB storage)
- Premium: ~$150/mes (storage ilimitado + geo-replication)

### Azure File Share (Standard)
- Storage: ~$0.06/GB/mes
- Transacciones: ~$0.004/10,000 ops
- 5 GB: ~$0.30/mes

## 🔒 Security Best Practices

1. **Usa Managed Identity** en lugar de admin credentials
2. **Escanea imágenes** con Azure Defender for Containers
3. **Usa Private Endpoints** para ACR en producción
4. **Rota secrets** regularmente si usas admin user
5. **Habilita audit logs** para ACR
6. **Limita network access** con firewall rules
7. **Usa HTTPS** siempre para exponer apps
8. **Encripta data at rest** con customer-managed keys

## 📚 Recursos Adicionales

- [Documentación de Azure Container Instances](https://learn.microsoft.com/azure/container-instances/)
- [Documentación de Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

## ❓ FAQ

**P: ¿Puedo usar Kubernetes en lugar de ACI?**
R: Sí, Azure Kubernetes Service (AKS) es para cargas más complejas. ACI es más simple y económico para workloads pequeños.

**P: ¿Soporta autoscaling?**
R: ACI no tiene autoscaling nativo. Para eso usa AKS con HPA.

**P: ¿Puedo usar Docker Compose?**
R: Sí, puedes convertir docker-compose.yml a ACI deployment.

**P: ¿Cuánto tarda en iniciar un contenedor?**
R: Típicamente 30-60 segundos para el primer inicio.

**P: ¿Hay límites de recursos?**
R: Por container group: Máx 4 vCPU y 16 GB RAM en Linux.

## 🐛 Troubleshooting

Ver el README de cada ejemplo para troubleshooting específico.

### Problema común: "Container failed to start"

```bash
# Ver logs detallados
az container logs --name <name> --resource-group <rg>

# Ver eventos
az container show --name <name> --resource-group <rg> \
  --query "containers[0].instanceView.events"
```

## 💬 Feedback

¿Encontraste un problema? ¿Tienes una sugerencia?
- Abre un issue en el repositorio
- Contribuye con un PR

---

**Happy containerizing! 🐳**
