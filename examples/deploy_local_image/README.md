# Desplegar Imagen Docker Local a Azure Container Instances

Esta guía te ayudará a desplegar tu imagen Docker local `portal_costos_cloud` a Azure.

## 🎯 Tu Situación Actual

```bash
# Tu imagen local
docker images
REPOSITORY                                           TAG       IMAGE ID       CREATED      SIZE
portal_costos_cloud-1-portal-costos                  latest    1bba138862f9   2 days ago   1.52GB
xpediego131194/portal_costos_cloud-1-portal-costos   latest    1bba138862f9   2 days ago   1.52GB

# Tu contenedor corriendo localmente
docker ps
CONTAINER ID   IMAGE                                 PORTS
80188d094636   portal_costos_cloud-1-portal-costos   0.0.0.0:8080->5000/tcp
```

**Tu app Flask corre en:**
- Puerto interno: `5000` (Flask)
- Puerto expuesto: `8080` (local)

## 🚀 Objetivo

Mover esta aplicación a Azure para que esté accesible 24/7 en internet.

## 📋 Prerrequisitos

1. ✅ Azure CLI instalado y autenticado
   ```bash
   az login
   az account show
   ```

2. ✅ Docker instalado y corriendo
   ```bash
   docker version
   ```

3. ✅ Terraform instalado
   ```bash
   terraform version
   ```

## 🏗️ Arquitectura que vamos a crear

```
┌─────────────────────┐
│   Tu Mac            │
│   Docker Image      │
│   (local)           │
└──────────┬──────────┘
           │ docker push
           ▼
┌─────────────────────┐
│   Azure Container   │
│   Registry (ACR)    │
│   (privado)         │
└──────────┬──────────┘
           │ pull
           ▼
┌─────────────────────┐
│   Azure Container   │
│   Instances (ACI)   │
│   (público)         │
│   http://xxx:5000   │
└─────────────────────┘
```

## 📝 Paso a Paso

### Paso 1: Crear la infraestructura en Azure

```bash
# Ir al directorio del ejemplo
cd examples/deploy_local_image

# Inicializar Terraform
terraform init

# Ver qué se va a crear
terraform plan

# Crear ACR + Container Instance
terraform apply
```

**¿Qué se crea?**
- ✅ Resource Group
- ✅ Azure Container Registry (ACR) para guardar tu imagen
- ✅ Container Instance (ACI) para correr tu app
- ⚠️ El container fallará inicialmente (es normal, aún no hay imagen)

### Paso 2: Obtener credenciales del ACR

```bash
# Ver el nombre y URL del ACR
terraform output acr_login_server
terraform output acr_name

# Ver el password (lo necesitarás)
terraform output acr_admin_password
```

### Paso 3: Login a ACR desde Docker

```bash
# Opción 1: Login con Azure CLI (recomendado)
az acr login --name <acr-name-from-output>

# Opción 2: Login con credenciales
docker login <acr-login-server> \
  --username <acr-admin-username> \
  --password <acr-admin-password>
```

**Ejemplo real:**
```bash
az acr login --name acrportalcostos12345678
# O
docker login acrportalcostos12345678.azurecr.io \
  --username acrportalcostos12345678 \
  --password "tu-password-aquí"
```

Deberías ver: `Login Succeeded`

### Paso 4: Tagear tu imagen local para ACR

```bash
# Ver tus imágenes locales
docker images | grep portal

# Tagear con el nombre del ACR
docker tag portal_costos_cloud-1-portal-costos:latest \
  <acr-login-server>/portal_costos_cloud:latest
```

**Ejemplo real:**
```bash
docker tag portal_costos_cloud-1-portal-costos:latest \
  acrportalcostos12345678.azurecr.io/portal_costos_cloud:latest
```

### Paso 5: Push de la imagen a ACR

```bash
docker push <acr-login-server>/portal_costos_cloud:latest
```

**Ejemplo real:**
```bash
docker push acrportalcostos12345678.azurecr.io/portal_costos_cloud:latest
```

Esto puede tardar varios minutos (tu imagen es de 1.52GB). Verás:
```
The push refers to repository [acrportalcostos12345678.azurecr.io/portal_costos_cloud]
a1b2c3d4e5f6: Pushed
...
latest: digest: sha256:abc123... size: 4321
```

### Paso 6: Verificar que la imagen está en ACR

```bash
# Ver repositorios
az acr repository list --name <acr-name>

# Ver tags
az acr repository show-tags \
  --name <acr-name> \
  --repository portal_costos_cloud
```

### Paso 7: Reiniciar el Container Instance

```bash
# Ver el nombre del container
terraform output container_fqdn

# Reiniciar (esto hará pull de la imagen)
az container restart \
  --name ci-portal-costos-dev \
  --resource-group rg-portal-costos-dev
```

### Paso 8: Verificar que funciona

```bash
# Ver logs (importante para debug)
az container logs \
  --name ci-portal-costos-dev \
  --resource-group rg-portal-costos-dev

# Ver URL de acceso
terraform output container_url

# Probar con curl
curl http://$(terraform output -raw container_fqdn):5000

# O abrir en navegador
open http://$(terraform output -raw container_fqdn):5000
```

## ✅ Verificación Final

Tu aplicación debería estar corriendo en:
```
http://<tu-fqdn>:5000
```

Por ejemplo: `http://portal-costos-dev-abc123.eastus.azurecontainer.io:5000`

## 🔄 Actualizaciones Futuras

Cuando hagas cambios en tu app:

```bash
# 1. Reconstruir imagen local
docker build -t portal_costos_cloud-1-portal-costos:latest .

# 2. Tagear con versión nueva
docker tag portal_costos_cloud-1-portal-costos:latest \
  <acr-login-server>/portal_costos_cloud:v2

# 3. Push
docker push <acr-login-server>/portal_costos_cloud:v2

# 4. Actualizar Terraform para usar :v2
# Editar main.tf, cambiar línea:
# image = "${module.acr.login_server}/portal_costos_cloud:v2"

# 5. Aplicar cambios
terraform apply

# O simplemente reiniciar si usas :latest
az container restart \
  --name ci-portal-costos-dev \
  --resource-group rg-portal-costos-dev
```

## 🐛 Troubleshooting

### Error: "docker: Error response from daemon: Get https://xxx.azurecr.io/v2/: unauthorized"

**Solución**: Login de nuevo al ACR
```bash
az acr login --name <acr-name>
```

### Error: "Failed to pull image: access denied"

**Solución**: Verifica que las credenciales en Terraform son correctas
```bash
terraform output acr_admin_username
terraform output acr_admin_password
```

### El contenedor no inicia o está en "Waiting"

**Solución**: Ver logs para debug
```bash
# Ver eventos
az container show \
  --name ci-portal-costos-dev \
  --resource-group rg-portal-costos-dev \
  --query "containers[0].instanceView.events"

# Ver logs
az container logs \
  --name ci-portal-costos-dev \
  --resource-group rg-portal-costos-dev
```

### Error: "ImagePullBackOff" o "ErrImagePull"

**Causas comunes:**
1. La imagen no existe en ACR → `az acr repository list --name <acr-name>`
2. Tag incorrecto → Verifica que el tag en Terraform coincide con el push
3. Credenciales incorrectas → Verifica admin_username y admin_password

### La app no responde en el puerto 5000

**Verifica:**
1. Tu app realmente escucha en puerto 5000 (no 8080)
2. El puerto está expuesto en el Dockerfile: `EXPOSE 5000`
3. Flask está configurado para escuchar en 0.0.0.0:
   ```python
   app.run(host='0.0.0.0', port=5000)
   ```

### Error: "Container group is in failed state"

```bash
# Ver estado detallado
az container show \
  --name ci-portal-costos-dev \
  --resource-group rg-portal-costos-dev \
  --query "{State:instanceView.state, Events:containers[0].instanceView.events}"
```

## 📊 Monitoreo

### Ver logs en tiempo real

```bash
az container attach \
  --name ci-portal-costos-dev \
  --resource-group rg-portal-costos-dev
```

### Entrar al contenedor (debug)

```bash
az container exec \
  --name ci-portal-costos-dev \
  --container-name portal-costos \
  --resource-group rg-portal-costos-dev \
  --exec-command "/bin/bash"

# Dentro del contenedor:
ls -la
ps aux
env | grep FLASK
```

## 🔒 Seguridad

### Variables de entorno sensibles

Si tu app necesita secrets (DB passwords, API keys, etc):

```hcl
# En main.tf, usa secure_environment_variables:
secure_environment_variables = {
  "DATABASE_PASSWORD" = "tu-password"
  "API_KEY"          = "tu-api-key"
  "SECRET_KEY"       = "tu-secret-key"
}
```

### Usar HTTPS

Para producción, considera:
1. Azure Application Gateway con SSL
2. Azure Front Door
3. Un reverse proxy (nginx) con certificado SSL

## 💰 Costos Estimados

- **ACR Standard**: ~$20/mes (incluye 100GB)
- **Storage adicional**: Tu imagen (1.52GB) está incluida
- **Container Instance**: 2 vCPU, 4GB RAM = ~$85/mes
- **Total**: ~$105/mes corriendo 24/7

**Tip para ahorrar:**
- Usa SKU Basic de ACR ($5/mes) si no necesitas geo-replication
- Reduce recursos a 1 vCPU, 2GB si tu app lo permite (~$42/mes)

## 📦 Optimización de Imagen

Tu imagen es de 1.52GB, lo cual es grande. Considera:

### Multi-stage build

```dockerfile
# Build stage
FROM python:3.11 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

Esto puede reducir el tamaño a ~500MB.

### Usar alpine

```dockerfile
FROM python:3.11-alpine
# Puede reducir a ~200-300MB
```

## 🔄 CI/CD

Para automatizar deployments, considera GitHub Actions:

```yaml
name: Deploy to Azure
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Login to ACR
        run: |
          az acr login --name ${{ secrets.ACR_NAME }}

      - name: Build and push
        run: |
          docker build -t ${{ secrets.ACR_NAME }}.azurecr.io/portal_costos_cloud:${{ github.sha }} .
          docker push ${{ secrets.ACR_NAME }}.azurecr.io/portal_costos_cloud:${{ github.sha }}

      - name: Restart container
        run: |
          az container restart --name ci-portal-costos-dev --resource-group rg-portal-costos-dev
```

## 🧹 Limpiar Recursos

Cuando quieras eliminar todo:

```bash
terraform destroy
```

Esto eliminará:
- Container Instance
- Container Registry (y todas las imágenes)
- Resource Group

## 🎓 Próximos Pasos

- Ver `../container_instance_with_volumes/` si necesitas persistir datos
- Ver `../container_instance_advanced/` si necesitas agregar Redis/cache
- Considera mover a AKS (Kubernetes) si tu app crece mucho

## 📞 Ayuda Adicional

Si tienes problemas, comparte:
1. Output de `terraform apply`
2. Output de `az container logs`
3. Output de `az container show`

---

**¡Buena suerte con tu deployment! 🚀**
