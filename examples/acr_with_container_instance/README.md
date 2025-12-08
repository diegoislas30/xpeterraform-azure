# Ejemplo: ACR + Container Instance con Managed Identity

Este ejemplo muestra cómo usar Azure Container Registry (ACR) con Container Instances usando **Managed Identity** para autenticación segura.

## ¿Qué hace este ejemplo?

- Crea un Azure Container Registry (Standard SKU)
- Despliega un Container Instance con System Managed Identity
- Configura permisos AcrPull automáticamente
- Usa imágenes privadas desde ACR sin credenciales

## Ventajas de Managed Identity

✅ **Sin secretos**: No necesitas almacenar passwords
✅ **Seguro**: Azure gestiona las identidades automáticamente
✅ **Recomendado**: Best practice para producción
✅ **Simple**: No necesitas rotar credenciales

## Uso

### 1. Desplegar la infraestructura

```bash
# Inicializar
terraform init

# Aplicar
terraform apply
```

### 2. Importar una imagen desde Docker Hub

Después del despliegue, importa una imagen:

```bash
# Ver el comando de importación
terraform output import_command

# Ejecutar el comando (ejemplo con nginx)
az acr import \
  --name <tu-acr-name> \
  --source docker.io/library/nginx:latest \
  --image nginx:latest
```

### 3. O subir tu propia imagen

```bash
# Login al ACR
az acr login --name <tu-acr-name>

# Build y push
docker build -t <tu-acr-name>.azurecr.io/myapp:v1 .
docker push <tu-acr-name>.azurecr.io/myapp:v1
```

### 4. Reiniciar el container para usar la nueva imagen

```bash
az container restart \
  --name ci-app-from-acr \
  --resource-group rg-acr-aci-example
```

### 5. Verificar que funciona

```bash
# Ver la URL
terraform output container_url

# Acceder
curl http://$(terraform output -raw container_url)
```

## Ver todos los próximos pasos

```bash
terraform output next_steps
```

## Arquitectura

```
┌─────────────────────┐
│   Docker Hub        │
│   (nginx:latest)    │
└──────────┬──────────┘
           │ az acr import
           ▼
┌─────────────────────┐
│   Azure Container   │
│   Registry (ACR)    │
│   myacr.azurecr.io  │
└──────────┬──────────┘
           │ AcrPull permission
           ▼
┌─────────────────────┐
│   Container         │
│   Instance (ACI)    │
│   + Managed ID      │
└─────────────────────┘
```

## Comparación: Admin User vs Managed Identity

### Admin User (Ejemplo alternativo)

```hcl
module "acr" {
  admin_enabled = true
}

module "container_instance" {
  image_registry_credentials = [{
    server   = module.acr.login_server
    username = module.acr.admin_username
    password = module.acr.admin_password
  }]
}
```

**Pros**: Simple, inmediato
**Contras**: Menos seguro, hay que rotar passwords

### Managed Identity (Este ejemplo) ✅

```hcl
module "container_instance" {
  identity_type = "SystemAssigned"
}

resource "azurerm_role_assignment" "acr_pull" {
  role_definition_name = "AcrPull"
  principal_id         = module.container_instance.identity[0].principal_id
}
```

**Pros**: Muy seguro, sin secretos, best practice
**Contras**: Requiere configuración de roles

## Costo estimado

- **ACR Standard**: ~$0.167/día (~$5/mes)
- **Storage**: Incluye 100GB
- **Container Instance**: ~$32/mes (1 vCPU, 1.5GB RAM)
- **Total**: ~$37/mes

## Limpiar recursos

```bash
terraform destroy
```

## Troubleshooting

### Error: "Failed to pull image"

Asegúrate de que:
1. La imagen existe en ACR: `az acr repository list --name <acr-name>`
2. El role assignment se creó: `az role assignment list --scope <acr-id>`
3. El container instance tiene managed identity habilitada

### Error: "ACR name not available"

El nombre del ACR debe ser globalmente único. Terraform genera uno aleatorio, pero si falla, ejecuta `terraform apply` de nuevo.

## Próximos pasos

- Ver `../container_instance_advanced/` para múltiples contenedores
- Ver `../container_instance_with_volumes/` para datos persistentes
