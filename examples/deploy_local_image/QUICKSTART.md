# 🚀 Quick Start - Deploy en 5 minutos

La forma más rápida de deployar tu `portal_costos_cloud` a Azure.

## Opción 1: Script Automatizado (Recomendado)

```bash
# 1. Ir al directorio
cd examples/deploy_local_image

# 2. Dar permisos al script
chmod +x deploy.sh

# 3. Ejecutar deployment completo
./deploy.sh full
```

Eso es todo! El script:
- ✅ Verifica prerrequisitos
- ✅ Crea infraestructura en Azure
- ✅ Sube tu imagen a ACR
- ✅ Despliega el container
- ✅ Te da la URL final

## Opción 2: Paso a Paso Manual

```bash
# 1. Crear infraestructura
terraform init
terraform apply

# 2. Login a ACR
az acr login --name $(terraform output -raw acr_name)

# 3. Tag y push de imagen
docker tag portal_costos_cloud-1-portal-costos:latest \
  $(terraform output -raw acr_login_server)/portal_costos_cloud:latest

docker push $(terraform output -raw acr_login_server)/portal_costos_cloud:latest

# 4. Reiniciar container
az container restart \
  --name ci-portal-costos-dev \
  --resource-group rg-portal-costos-dev

# 5. Ver URL
terraform output container_url
```

## Actualizar la App

```bash
# Opción rápida con script
./deploy.sh update

# O manual
docker tag portal_costos_cloud-1-portal-costos:latest \
  $(terraform output -raw acr_login_server)/portal_costos_cloud:latest
docker push $(terraform output -raw acr_login_server)/portal_costos_cloud:latest
az container restart --name ci-portal-costos-dev --resource-group rg-portal-costos-dev
```

## Ver Logs

```bash
# Con script
./deploy.sh logs

# O manual
az container logs --name ci-portal-costos-dev --resource-group rg-portal-costos-dev
```

## Comandos Útiles del Script

```bash
./deploy.sh full      # Deployment completo
./deploy.sh update    # Actualizar app
./deploy.sh logs      # Ver logs
./deploy.sh verify    # Verificar estado
./deploy.sh destroy   # Eliminar todo
./deploy.sh help      # Ayuda
```

## Troubleshooting Rápido

**Container no inicia:**
```bash
./deploy.sh logs
```

**Verificar estado:**
```bash
./deploy.sh verify
```

**Recrear todo:**
```bash
./deploy.sh destroy
./deploy.sh full
```

## ⏱️ Tiempos Estimados

- Primera vez (full deployment): ~10-15 minutos
- Actualización de app: ~3-5 minutos
- Ver logs: Instantáneo

## 💰 Costo

~$105/mes corriendo 24/7

Para reducir costos, edita `main.tf`:
```hcl
cpu    = 1      # En lugar de 2
memory = 2      # En lugar de 4
```
Costo reducido: ~$42/mes

## 📖 Más Información

Ver [README.md](./README.md) para documentación completa.
