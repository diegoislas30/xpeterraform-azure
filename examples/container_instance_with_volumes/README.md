# Ejemplo: Container Instance con Volúmenes Persistentes

Este ejemplo demuestra cómo usar **Azure File Share** para persistir datos en contenedores.

## ¿Por qué necesitas volúmenes?

Los contenedores son **efímeros** por naturaleza:
- ❌ Los datos se pierden cuando el contenedor se reinicia
- ❌ No puedes compartir datos entre contenedores fácilmente
- ❌ No puedes acceder a los datos desde fuera del contenedor

Con volúmenes de Azure File Share:
- ✅ Los datos persisten después de reinicios
- ✅ Múltiples contenedores pueden compartir datos
- ✅ Puedes acceder a los datos desde fuera (Azure Portal, CLI, Storage Explorer)
- ✅ Backups automáticos con Azure Backup

## Arquitectura

```
┌──────────────────────────────────────┐
│     Azure Storage Account            │
│                                      │
│  ┌────────────────────────────┐    │
│  │   File Share: container-data│    │
│  │   - config.json             │    │
│  │   - /app-data/              │    │
│  │   Quota: 5 GB               │    │
│  └────────────┬─────────────────┘    │
└───────────────┼──────────────────────┘
                │ SMB 3.0
                ▼
┌──────────────────────────────────────┐
│     Container Instance               │
│                                      │
│  Volume Mounts:                     │
│  - /mnt/data (read-write)           │
│  - /etc/app  (read-only)            │
│                                      │
│  ┌────────────────────────┐         │
│  │   nginx-with-data      │         │
│  │   CPU: 1.0             │         │
│  │   RAM: 1.5GB           │         │
│  └────────────────────────┘         │
└──────────────────────────────────────┘
```

## ¿Qué hace este ejemplo?

1. Crea un Storage Account
2. Crea un Azure File Share (5GB)
3. Sube un archivo de configuración (`config.json`)
4. Despliega un contenedor con 2 volúmenes montados:
   - `/mnt/data` - Read/Write para datos de aplicación
   - `/etc/app` - Read-Only para configuración

## Uso

```bash
# Inicializar
terraform init

# Aplicar
terraform apply

# Ver información de los volúmenes
terraform output mount_info

# Ver comandos de acceso
terraform output access_commands
```

## Verificar los volúmenes

### 1. Desde el contenedor

```bash
# Conectarse al contenedor
az container exec \
  --name ci-app-with-volumes \
  --container-name nginx-with-data \
  --resource-group rg-container-volumes-example \
  --exec-command "/bin/bash"

# Dentro del contenedor:
ls -la /mnt/data                    # Ver directorio de datos
cat /etc/app/config.json            # Ver configuración
echo "Hello" > /mnt/data/test.txt   # Crear archivo
cat /mnt/data/test.txt              # Leer archivo
```

### 2. Desde Azure CLI

```bash
# Ver archivos en el File Share
az storage file list \
  --account-name <storage-account-name> \
  --account-key "<storage-key>" \
  --share-name container-data

# Descargar un archivo
az storage file download \
  --account-name <storage-account-name> \
  --account-key "<storage-key>" \
  --share-name container-data \
  --path test.txt \
  --dest ./test.txt
```

### 3. Desde Azure Portal

1. Ve a Storage Account → File Shares
2. Haz clic en "container-data"
3. Explora archivos en el navegador
4. Sube/descarga archivos con drag & drop

### 4. Montar localmente (Windows/Linux/Mac)

**Windows:**
```powershell
net use Z: \\<storage-account>.file.core.windows.net\container-data /u:AZURE\<storage-account> <storage-key>
```

**Linux/Mac:**
```bash
sudo mount -t cifs //<storage-account>.file.core.windows.net/container-data /mnt/azure \
  -o vers=3.0,username=<storage-account>,password=<storage-key>,dir_mode=0777,file_mode=0777
```

## Casos de uso comunes

### 1. Base de datos en contenedor

```hcl
containers = [{
  name   = "postgres"
  image  = "postgres:15"
  volumes = [{
    name       = "postgres-data"
    mount_path = "/var/lib/postgresql/data"
    # Los datos de la DB persisten aquí
  }]
}]
```

### 2. Aplicación con uploads de usuarios

```hcl
containers = [{
  name   = "webapp"
  image  = "myapp:v1"
  volumes = [{
    name       = "user-uploads"
    mount_path = "/app/uploads"
    # Archivos subidos por usuarios
  }]
}]
```

### 3. Logs persistentes

```hcl
containers = [{
  name   = "app"
  image  = "myapp:v1"
  volumes = [{
    name       = "app-logs"
    mount_path = "/var/log/app"
    read_only  = false
  }]
}]
```

### 4. Configuración compartida (read-only)

```hcl
containers = [
  {
    name = "app1"
    volumes = [{
      name       = "shared-config"
      mount_path = "/etc/config"
      read_only  = true  # Solo lectura
    }]
  },
  {
    name = "app2"
    volumes = [{
      name       = "shared-config"
      mount_path = "/etc/config"
      read_only  = true
    }]
  }
]
```

## Ventajas de Azure File Share

✅ **SMB 3.0**: Compatible con Windows y Linux
✅ **Totalmente gestionado**: Azure maneja la infraestructura
✅ **Accesible**: Desde contenedores, VMs, local, Azure Portal
✅ **Backups**: Azure Backup integrado
✅ **Seguro**: Encriptación en tránsito y en reposo
✅ **Escalable**: Hasta 100 TiB por share

## Alternativas de almacenamiento

### Azure File Share (Este ejemplo) ✅
- **Protocolo**: SMB/NFS
- **Casos de uso**: Archivos compartidos, configuraciones
- **Performance**: Standard/Premium
- **Precio**: ~$0.06/GB/mes (Standard)

### Azure Blob Storage
- **Protocolo**: REST API
- **Casos de uso**: Object storage, backups
- **Performance**: Hot/Cool/Archive
- **Precio**: ~$0.018/GB/mes (Hot)

### Azure Disk
- **Protocolo**: Block storage
- **Casos de uso**: Discos de VMs
- **Performance**: Standard/Premium SSD
- **Limitación**: No soportado en ACI

### emptyDir (Temporal)
- **Tipo**: Volumen efímero
- **Casos de uso**: Cache temporal
- **Persistencia**: Se pierde al reiniciar
- **Precio**: Gratis

## Performance Tips

### Para mejor performance:
1. **Usa Premium File Shares** para cargas IO intensivas
2. **Misma región**: Storage y Container en la misma región
3. **Caching**: Usa volúmenes read-only cuando sea posible
4. **Tamaño de share**: Mayor quota = mejor performance

### Premium vs Standard

**Standard (Este ejemplo)**
- Hasta 60 MiB/s por share
- Pago por uso (GB almacenado)
- Ideal para: Configs, logs, datos no críticos

**Premium**
- Hasta 300+ MiB/s por share
- Pago por capacidad provisionada
- Ideal para: Databases, apps de alto tráfico

## Seguridad

### Proteger el Storage Account Key

**❌ Malo: Hardcodear la key**
```hcl
storage_account_key = "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
```

**✅ Bueno: Usar Key Vault**
```hcl
data "azurerm_key_vault_secret" "storage_key" {
  name         = "storage-account-key"
  key_vault_id = var.key_vault_id
}

secure_environment_variables = {
  STORAGE_KEY = data.azurerm_key_vault_secret.storage_key.value
}
```

### Limitar acceso de red

```hcl
resource "azurerm_storage_account" "example" {
  network_rules {
    default_action = "Deny"
    ip_rules       = ["203.0.113.0/24"]
    bypass         = ["AzureServices"]
  }
}
```

## Backup y Recuperación

### Habilitar Azure Backup

```bash
# Crear Recovery Services Vault
az backup vault create \
  --resource-group rg-backups \
  --name vault-backups \
  --location eastus

# Habilitar backup para el File Share
az backup protection enable-for-azurefileshare \
  --vault-name vault-backups \
  --resource-group rg-backups \
  --policy-name DefaultPolicy \
  --storage-account <storage-account-name> \
  --azure-file-share container-data
```

### Restaurar desde backup

```bash
az backup restore restore-azurefileshare \
  --vault-name vault-backups \
  --resource-group rg-backups \
  --rp-name <recovery-point> \
  --storage-account <storage-account-name> \
  --azure-file-share container-data
```

## Costo estimado

- **Container Instance**: 1 vCPU, 1.5GB = ~$32/mes
- **Storage Account**: Standard LRS = ~$0.05/GB/mes
- **File Share**: 5GB = ~$0.25/mes
- **Transacciones**: Despreciable para uso normal
- **Total**: ~$32.25/mes

## Troubleshooting

### Error: "Mount failed: Operation not permitted"

Verifica:
1. Storage Account Key es correcto
2. File Share existe
3. Container tiene permisos de red

### Error: "Volume mount path already exists"

Asegúrate de que los `mount_path` son únicos por contenedor.

### Los datos no persisten

Verifica que estás usando Azure File Share, no `emptyDir`.

## Limpiar recursos

```bash
terraform destroy
```

**Nota**: Esto eliminará todos los datos en el File Share.

## Próximos pasos

- Ver `../container_instance_advanced/` para sidecar pattern
- Ver `../acr_with_container_instance/` para imágenes privadas
