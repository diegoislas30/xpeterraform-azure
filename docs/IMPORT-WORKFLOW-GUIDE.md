# 🚀 Guía Rápida: Importar Recursos desde GitHub Actions

Esta guía te muestra cómo usar el workflow de GitHub Actions para importar recursos existentes de Azure a Terraform **sin necesidad de tener Terraform instalado localmente**.

---

## ✅ Ventajas de este Método

- 🎯 **Sin instalación local** - No necesitas Terraform en tu máquina
- 🔒 **Backend remoto automático** - El workflow ya está configurado con el blob storage
- 📝 **Auditado** - Queda registro en GitHub de quién importó qué
- ✅ **Validación automática** - Ejecuta `terraform plan` automáticamente
- 🔄 **State siempre sincronizado** - No hay riesgo de desincronización

---

## 🎯 Flujo Completo

```
1. Abre GitHub → Actions
   ↓
2. Selecciona "Import Azure Resource"
   ↓
3. Click "Run workflow"
   ↓
4. Llena el formulario
   ↓
5. Workflow descubre el recurso en Azure
   ↓
6. Workflow genera configuración Terraform
   ↓
7. Workflow importa al state remoto
   ↓
8. Workflow valida con terraform plan
   ↓
9. Workflow crea commit y PR automáticamente
   ↓
10. Tú revisas y apruebas el PR
```

---

## 📝 Paso a Paso

### 1. Abrir GitHub Actions

1. Ve a tu repositorio en GitHub
2. Click en la pestaña **"Actions"**
3. En el menú izquierdo, busca **"Import Azure Resource"**
4. Click en **"Run workflow"** (botón azul)

### 2. Llenar el Formulario

El formulario tiene los siguientes campos:

#### **resource_type** (requerido)
Selecciona el tipo de recurso del dropdown:
- `resource_group`
- `virtual_network`
- `subnet`
- `network_security_group`
- `storage_account`
- `key_vault`
- `virtual_machine_linux`
- `virtual_machine_windows`
- `network_interface`
- `managed_disk`
- `public_ip`
- `container_registry`

#### **resource_name** (requerido)
El nombre exacto del recurso en Azure
- Ejemplo: `vnet-production`

#### **resource_group** (requerido)
El Resource Group donde está el recurso
- Ejemplo: `rg-production-eastus`

#### **terraform_resource_name** (requerido)
Nombre corto para el recurso en Terraform (sin espacios ni caracteres especiales)
- Ejemplo: `prod`, `main`, `web01`
- Se usará en: `azurerm_virtual_network.prod`

#### **branch_name** (opcional)
Nombre de la rama donde se hará el import
- Si lo dejas vacío, se genera automáticamente: `import/[tipo]-[nombre]`
- Ejemplo auto: `import/virtual_network-prod`

#### **use_module** (opcional - checkbox)
Solo para VMs: ¿Usar el módulo `virtual_machine` del repositorio?
- ✅ Recomendado para VMs complejas
- ❌ Si quieres un resource simple

---

## 🎬 Ejemplo 1: Importar Virtual Network

### Datos del recurso en Azure:
```
Nombre: vnet-production
Resource Group: rg-production-eastus
Region: East US
Address Space: 10.0.0.0/16
```

### Formulario en GitHub:
```yaml
resource_type: virtual_network
resource_name: vnet-production
resource_group: rg-production-eastus
terraform_resource_name: prod
branch_name: (dejar vacío)
use_module: false
```

### Lo que hace el workflow:

1. **Descubre el recurso:**
   ```bash
   az network vnet show -g rg-production-eastus -n vnet-production
   ```

2. **Genera configuración:**
   ```hcl
   resource "azurerm_virtual_network" "prod" {
     name                = "vnet-production"
     resource_group_name = "rg-production-eastus"
     location            = "eastus"
     address_space       = ["10.0.0.0/16"]

     tags = {
       environment = "production"
       managed-by  = "terraform"
     }
   }
   ```

3. **Importa al state remoto:**
   ```bash
   terraform import azurerm_virtual_network.prod \
     /subscriptions/12345.../virtualNetworks/vnet-production
   ```

4. **Valida:**
   ```bash
   terraform plan
   # ✅ No changes - Perfect match!
   ```

5. **Crea PR automáticamente:**
   - Rama: `import/virtual_network-prod`
   - Archivo: `import.tf`
   - PR listo para review

---

## 🎬 Ejemplo 2: Importar Storage Account

### Formulario:
```yaml
resource_type: storage_account
resource_name: mystorageaccount123
resource_group: rg-production-eastus
terraform_resource_name: main
branch_name: import/storage-main
use_module: false
```

### Resultado:
```hcl
# import.tf
resource "azurerm_storage_account" "main" {
  name                     = "mystorageaccount123"
  resource_group_name      = "rg-production-eastus"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    environment = "production"
  }
}
```

---

## 🎬 Ejemplo 3: Importar VM con Módulo

### Formulario:
```yaml
resource_type: virtual_machine_linux
resource_name: vm-web-01
resource_group: rg-production-eastus
terraform_resource_name: web01
branch_name: import/vm-web01
use_module: true  ← IMPORTANTE
```

### Resultado:
```hcl
# import.tf
module "web01" {
  source = "./modules/virtual_machine"

  vm_name             = "vm-web-01"
  resource_group_name = "rg-production-eastus"
  location            = "eastus"
  subnet_id           = "COMPLETAR_SUBNET_ID"  # ← Requiere ajuste manual

  os_type = "linux"
  vm_size = "Standard_D2s_v3"

  use_marketplace_image = true
  marketplace_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username = "azureuser"
  admin_ssh_keys = [
    {
      username   = "azureuser"
      public_key = file("~/.ssh/id_rsa.pub")  # ← Requiere ajuste
    }
  ]

  tags = {
    environment = "production"
  }
}
```

**Nota:** Las VMs requieren ajustes manuales (subnet_id, ssh keys, etc.)

---

## 📊 Interpretando el Summary del Workflow

Después de ejecutar, verás un summary en GitHub Actions:

### ✅ Import Exitoso (Plan perfecto)

```markdown
# ✅ Recurso Importado a Terraform

Estado de Importación:
- Recurso encontrado: ✅ Si
- Importado al state: ✅ Si
- Backend remoto: ✅ Azure Blob Storage
- Terraform plan: perfect
- Cambios detectados: 0

⏭️ Próximos Pasos:
1. ✅ El recurso ha sido importado
2. ✅ PR creado automáticamente
3. ⏭️ Revisa y aprueba el PR
```

**Acción:** Revisar y aprobar el PR directamente.

---

### ⚠️ Import con Ajustes Necesarios

```markdown
# ✅ Recurso Importado a Terraform

Estado de Importación:
- Recurso encontrado: ✅ Si
- Importado al state: ✅ Si
- Backend remoto: ✅ Azure Blob Storage
- Terraform plan: needs_adjustment
- Cambios detectados: 3

⚠️ Ajustes Necesarios:
La configuración requiere ajustes manuales.

⏭️ Próximos Pasos:
1. ✅ El recurso ha sido importado al state remoto
2. ✅ La configuración está en la rama import/...
3. ⏭️ Haz pull de la rama localmente
4. ⏭️ Ajusta import.tf según las diferencias
5. ⏭️ Ejecuta terraform plan hasta "No changes"
6. ⏭️ Crea PR para review
```

**Acción:** Hacer pull de la rama y ajustar manualmente.

---

## 🔧 Ajustes Manuales Comunes

### 1. VMs - Completar subnet_id

```hcl
# Antes (generado)
subnet_id = "COMPLETAR_SUBNET_ID"

# Después (corregido)
subnet_id = azurerm_subnet.web.id
# O el ID completo:
subnet_id = "/subscriptions/.../subnets/subnet-web"
```

### 2. VMs - Actualizar SSH keys

```hcl
# Antes
admin_ssh_keys = [
  {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")  # No funciona en CI/CD
  }
]

# Después
admin_ssh_keys = [
  {
    username   = "azureuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB..."  # Clave real
  }
]
```

### 3. Storage - Configuraciones por defecto

```hcl
# Agregar configuraciones que no están explícitas
resource "azurerm_storage_account" "main" {
  name                     = "mystorageaccount"
  resource_group_name      = "rg-prod"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Agregar estas si están en el recurso real:
  min_tls_version          = "TLS1_2"
  enable_https_traffic_only = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = {
    environment = "production"
  }
}
```

---

## 🔄 Workflow Completo de Ajuste

Si el import necesita ajustes:

```bash
# 1. Pull la rama creada por el workflow
git fetch origin
git checkout import/virtual_network-prod

# 2. Revisar el archivo import.tf
cat import.tf

# 3. Inicializar Terraform con backend remoto (usa la misma rama)
terraform init \
  -backend-config="resource_group_name=terraform" \
  -backend-config="storage_account_name=xpeterraformpoc" \
  -backend-config="container_name=terraform-tfstate" \
  -backend-config="key=import/virtual_network-prod.tfstate"

# 4. Ver diferencias
terraform plan

# 5. Ajustar import.tf según las diferencias
nano import.tf

# 6. Validar ajustes
terraform plan
# Repetir hasta: "No changes. Infrastructure matches configuration."

# 7. Commit ajustes
git add import.tf
git commit -m "fix: Adjust import.tf configuration"
git push origin import/virtual_network-prod

# 8. Crear PR
gh pr create --title "Import VNet production"
```

---

## 📋 Checklist de Import

- [ ] Formulario lleno correctamente
- [ ] Workflow ejecutado sin errores
- [ ] Recurso importado al state remoto
- [ ] Rama creada en GitHub
- [ ] Si `plan = perfect`:
  - [ ] PR creado automáticamente
  - [ ] Revisar y aprobar PR
- [ ] Si `plan = needs_adjustment`:
  - [ ] Pull de la rama localmente
  - [ ] Ajustar import.tf
  - [ ] Validar con terraform plan
  - [ ] Push ajustes
  - [ ] Crear PR manualmente

---

## 🎯 Tips y Mejores Prácticas

### 1. Nombrado Consistente

```
❌ Mal:
terraform_resource_name: mi_recurso_2024_v2

✅ Bien:
terraform_resource_name: prod
terraform_resource_name: main
terraform_resource_name: web01
```

### 2. Estructura de Ramas

```
✅ Recomendado:
import/virtual_network-prod
import/storage-main
import/vm-web01

❌ Evitar:
feature/import-stuff
temp-branch
```

### 3. Después del Import

1. **Revisar tags** - Asegúrate que los tags sean consistentes
2. **Considerar módulos** - Para recursos complejos (VMs, SQL)
3. **Mover a archivo apropiado** - No dejar todo en `import.tf`
4. **Documentar** - Agregar comentarios sobre configuraciones especiales

### 4. Recursos Relacionados

Importa en orden de dependencias:

```
1. Resource Group
   ↓
2. Virtual Network
   ↓
3. Subnets
   ↓
4. NSGs
   ↓
5. NICs
   ↓
6. VMs
```

---

## ❓ FAQ

### ¿Puedo importar múltiples recursos a la vez?

No, el workflow importa de uno en uno. Esto es intencional para:
- Mayor control
- Validación individual
- Mejor trazabilidad

### ¿Qué pasa con el tfstate local?

No hay tfstate local. El workflow usa el backend remoto directamente, así que no hay riesgo de desincronización.

### ¿Puedo cancelar el import?

Sí, pero el recurso ya estará en el state remoto. Para removerlo:

```bash
# Localmente
terraform state rm azurerm_virtual_network.prod
```

### ¿El workflow puede fallar?

Sí, puede fallar si:
- El recurso no existe en Azure
- No tienes permisos para verlo
- El Resource Group es incorrecto
- Hay un error en el provider

Revisa los logs del workflow para más detalles.

### ¿Requiere aprobación?

Sí, el job `import` usa el environment `prd`, que requiere aprobación manual antes de ejecutar el import.

---

## 📞 Soporte

Si tienes problemas:

1. Revisa los logs del workflow en GitHub Actions
2. Consulta la [documentación completa](../IMPORT-GUIDE.md)
3. Contacta al equipo de infraestructura

---

## 🔗 Referencias

- [Workflow completo](./.github/workflows/import-resource.yml)
- [Documentación de Terraform Import](https://www.terraform.io/docs/cli/import/)
- [AzureRM Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
