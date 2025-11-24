# Módulo de Azure Virtual Networks (VNets)

## Descripción

Módulo de Terraform para crear y gestionar Azure Virtual Networks (VNets) con soporte completo para:
- Creación de Virtual Networks con múltiples rangos de direcciones
- Gestión de subnets con configuración avanzada
- Servicios delegados para recursos de Azure específicos
- Service Endpoints para conectividad segura a servicios de Azure
- Políticas de Private Endpoints
- Asociación automática con Route Tables
- VNet Peering bidireccional

## Recursos Creados

Este módulo crea los siguientes recursos de Azure:

| Recurso | Tipo | Descripción |
|---------|------|-------------|
| Virtual Network | `azurerm_virtual_network` | Red virtual principal |
| Subnets | `azurerm_subnet` | Subnets dentro de la VNet |
| Route Table Association | `azurerm_subnet_route_table_association` | Asociación de subnets con route tables (opcional) |
| VNet Peering (Local) | `azurerm_virtual_network_peering` | Peering desde la VNet local hacia VNet remota |
| VNet Peering (Remote) | `azurerm_virtual_network_peering` | Peering desde la VNet remota hacia VNet local |

## Uso

### Ejemplo Básico (VNet Simple sin Peerings)

```hcl
module "vnet_simple" {
  source              = "./modules/vnets"
  vnet_name           = "vnet-app-prod"
  location            = "eastus"
  resource_group_name = "rg-networking-prod"
  address_space       = ["10.10.0.0/16"]

  subnets = [
    {
      name           = "subnet-web"
      address_prefix = "10.10.1.0/24"
    },
    {
      name           = "subnet-app"
      address_prefix = "10.10.2.0/24"
    },
    {
      name           = "subnet-data"
      address_prefix = "10.10.3.0/24"
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "DevOps Team"
    xpeowner = "devops@xpertal.com"
    proyecto = "app-platform"
    ambiente = "production"
  }
}
```

### Ejemplo con Service Endpoints

```hcl
module "vnet_with_endpoints" {
  source              = "./modules/vnets"
  vnet_name           = "vnet-secure-prod"
  location            = "eastus"
  resource_group_name = "rg-networking-prod"
  address_space       = ["10.20.0.0/16"]

  subnets = [
    {
      name              = "subnet-app"
      address_prefix    = "10.20.1.0/24"
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.Sql",
        "Microsoft.KeyVault"
      ]
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "Security Team"
    xpeowner = "security@xpertal.com"
    proyecto = "secure-platform"
    ambiente = "production"
  }
}
```

### Ejemplo con Servicios Delegados (Delegation)

#### Azure Functions / App Service

```hcl
module "vnet_functions" {
  source              = "./modules/vnets"
  vnet_name           = "vnet-functions-prod"
  location            = "eastus"
  resource_group_name = "rg-functions-prod"
  address_space       = ["10.30.0.0/16"]

  subnets = [
    {
      name           = "subnet-functions"
      address_prefix = "10.30.1.0/24"
      delegation = {
        name = "delegation-functions"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "Development Team"
    xpeowner = "dev@xpertal.com"
    proyecto = "serverless-app"
    ambiente = "production"
  }
}
```

#### SQL Managed Instance

```hcl
module "vnet_sqlmi" {
  source              = "./modules/vnets"
  vnet_name           = "vnet-sqlmi-prod"
  location            = "eastus"
  resource_group_name = "rg-database-prod"
  address_space       = ["10.40.0.0/16"]

  subnets = [
    {
      name           = "subnet-sqlmi"
      address_prefix = "10.40.1.0/24"
      delegation = {
        name = "delegation-sqlmi"
        service_delegation = {
          name = "Microsoft.Sql/managedInstances"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
          ]
        }
      }
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "DBA Team"
    xpeowner = "dba@xpertal.com"
    proyecto = "database-platform"
    ambiente = "production"
  }
}
```

#### Azure Container Instances (ACI)

```hcl
subnets = [
  {
    name           = "subnet-aci"
    address_prefix = "10.50.1.0/24"
    delegation = {
      name = "delegation-aci"
      service_delegation = {
        name    = "Microsoft.ContainerInstance/containerGroups"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
]
```

#### Azure Databricks

```hcl
subnets = [
  {
    name           = "subnet-databricks-private"
    address_prefix = "10.60.1.0/24"
    delegation = {
      name = "delegation-databricks"
      service_delegation = {
        name = "Microsoft.Databricks/workspaces"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
          "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
        ]
      }
    }
  }
]
```

### Ejemplo con Route Tables

```hcl
# Primero crear el módulo de route table
module "route_table_firewall" {
  source              = "./modules/route_table"
  rt_name             = "rt-firewall-prod"
  resource_group_name = "rg-networking-prod"
  location            = "eastus"

  routes = [
    {
      name                   = "route-to-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.100.1.4"
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "Network Team"
    xpeowner = "network@xpertal.com"
    proyecto = "networking"
    ambiente = "production"
  }
}

# Luego crear la VNet con asociación automática
module "vnet_with_routing" {
  source              = "./modules/vnets"
  vnet_name           = "vnet-app-prod"
  location            = "eastus"
  resource_group_name = "rg-networking-prod"
  address_space       = ["10.10.0.0/16"]

  subnets = [
    {
      name           = "subnet-web"
      address_prefix = "10.10.1.0/24"
      route_table_id = module.route_table_firewall.rt_id
    },
    {
      name           = "subnet-app"
      address_prefix = "10.10.2.0/24"
      route_table_id = module.route_table_firewall.rt_id
    },
    {
      name           = "subnet-data"
      address_prefix = "10.10.3.0/24"
      # Esta subnet no tendrá route table asociada
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "DevOps Team"
    xpeowner = "devops@xpertal.com"
    proyecto = "app-platform"
    ambiente = "production"
  }
}
```

### Ejemplo con Private Endpoints

```hcl
module "vnet_private_endpoints" {
  source              = "./modules/vnets"
  vnet_name           = "vnet-private-prod"
  location            = "eastus"
  resource_group_name = "rg-networking-prod"
  address_space       = ["10.70.0.0/16"]

  subnets = [
    {
      name                                      = "subnet-privateendpoints"
      address_prefix                            = "10.70.1.0/24"
      private_endpoint_network_policies_enabled = false
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "Security Team"
    xpeowner = "security@xpertal.com"
    proyecto = "private-connectivity"
    ambiente = "production"
  }
}
```

### Ejemplo Hub-Spoke con Peering

```hcl
# VNet Hub
module "vnet_hub" {
  source              = "./modules/vnets"
  vnet_name           = "vnet-hub-prod"
  location            = "eastus"
  resource_group_name = "rg-hub-prod"
  address_space       = ["10.100.0.0/16"]

  subnets = [
    {
      name           = "subnet-firewall"
      address_prefix = "10.100.1.0/24"
    },
    {
      name           = "subnet-gateway"
      address_prefix = "10.100.2.0/24"
    }
  ]

  peerings = [
    {
      name             = "hub-to-spoke1"
      remote_vnet_id   = module.vnet_spoke1.vnet_id
      remote_vnet_name = module.vnet_spoke1.vnet_name
      remote_rg_name   = "rg-spoke1-prod"

      local = {
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = true
        use_remote_gateways          = false
      }

      remote = {
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = false
        use_remote_gateways          = true
      }
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "Network Team"
    xpeowner = "network@xpertal.com"
    proyecto = "hub-infrastructure"
    ambiente = "production"
  }
}

# VNet Spoke
module "vnet_spoke1" {
  source              = "./modules/vnets"
  vnet_name           = "vnet-spoke1-prod"
  location            = "eastus"
  resource_group_name = "rg-spoke1-prod"
  address_space       = ["10.110.0.0/16"]

  subnets = [
    {
      name           = "subnet-app"
      address_prefix = "10.110.1.0/24"
    },
    {
      name           = "subnet-data"
      address_prefix = "10.110.2.0/24"
    }
  ]

  tags = {
    UDN      = "Xpertal"
    OWNER    = "App Team"
    xpeowner = "app@xpertal.com"
    proyecto = "application-workloads"
    ambiente = "production"
  }
}
```

## Inputs

| Nombre | Descripción | Tipo | Requerido | Default |
|--------|-------------|------|-----------|---------|
| `vnet_name` | Nombre de la Virtual Network | `string` | Sí | - |
| `resource_group_name` | Nombre del Resource Group donde se creará la VNet | `string` | Sí | - |
| `location` | Ubicación de Azure donde se creará la VNet | `string` | Sí | - |
| `address_space` | Espacio de direcciones CIDR de la VNet | `list(string)` | Sí | - |
| `subnets` | Lista de subnets a crear | `list(object)` | No | `[]` |
| `peerings` | Lista de peerings a crear | `list(object)` | No | `[]` |
| `tags` | Etiquetas a aplicar a los recursos | `object` | Sí | - |

### Estructura del objeto `subnets`

```hcl
subnets = [
  {
    name                                      = string           # Nombre de la subnet (requerido)
    address_prefix                            = string           # CIDR de la subnet (requerido)
    service_endpoints                         = list(string)     # Service endpoints (opcional, default: [])
    private_endpoint_network_policies_enabled = bool             # Habilitar políticas de red para PE (opcional, default: true)
    route_table_id                            = string           # ID de route table a asociar (opcional)
    delegation                                = object({         # Delegación de servicio (opcional)
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })
  }
]
```

### Estructura del objeto `peerings`

```hcl
peerings = [
  {
    name             = string  # Nombre del peering
    remote_vnet_id   = string  # ID de la VNet remota
    remote_vnet_name = string  # Nombre de la VNet remota
    remote_rg_name   = string  # Nombre del RG de la VNet remota

    local = object({
      allow_virtual_network_access = bool
      allow_forwarded_traffic      = bool
      allow_gateway_transit        = bool
      use_remote_gateways          = bool
    })

    remote = object({
      allow_virtual_network_access = bool
      allow_forwarded_traffic      = bool
      allow_gateway_transit        = bool
      use_remote_gateways          = bool
    })
  }
]
```

### Estructura del objeto `tags`

```hcl
tags = {
  UDN      = string  # Unidad de negocio
  OWNER    = string  # Propietario del recurso
  xpeowner = string  # Email del propietario
  proyecto = string  # Nombre del proyecto
  ambiente = string  # Ambiente (dev, qa, prod, etc.)
}
```

## Outputs

| Nombre | Descripción | Tipo |
|--------|-------------|------|
| `vnet_id` | ID completo de la Virtual Network | `string` |
| `vnet_name` | Nombre de la Virtual Network | `string` |
| `vnet_address_space` | Espacio de direcciones de la VNet | `list(string)` |
| `subnet_ids` | Mapa de IDs de subnets (nombre => id) | `map(string)` |
| `subnet_names` | Lista de nombres de subnets | `list(string)` |
| `subnet_address_prefixes` | Mapa de prefijos de direcciones (nombre => prefixes) | `map(list(string))` |
| `subnets_full` | Información completa de todas las subnets | `map(object)` |

### Uso de Outputs

```hcl
# Referenciar el ID de la VNet
module.vnet_app.vnet_id

# Referenciar ID de una subnet específica
module.vnet_app.subnet_ids["subnet-web"]

# Iterar sobre todas las subnets
for_each = module.vnet_app.subnet_ids

# Obtener información completa de una subnet
module.vnet_app.subnets_full["subnet-web"].address_prefixes
```

## Service Endpoints Soportados

Los siguientes service endpoints están disponibles en Azure:

| Service Endpoint | Descripción |
|-----------------|-------------|
| `Microsoft.Storage` | Azure Storage (Blob, File, Queue, Table) |
| `Microsoft.Sql` | Azure SQL Database |
| `Microsoft.AzureCosmosDB` | Azure Cosmos DB |
| `Microsoft.KeyVault` | Azure Key Vault |
| `Microsoft.ServiceBus` | Azure Service Bus |
| `Microsoft.EventHub` | Azure Event Hub |
| `Microsoft.Web` | Azure App Service |
| `Microsoft.ContainerRegistry` | Azure Container Registry |
| `Microsoft.CognitiveServices` | Azure Cognitive Services |

## Servicios Delegados Comunes

### Microsoft.Web/serverFarms
- **Uso**: Azure Functions, App Service
- **Actions**: `["Microsoft.Network/virtualNetworks/subnets/action"]`

### Microsoft.Sql/managedInstances
- **Uso**: SQL Managed Instance
- **Actions**:
  - `Microsoft.Network/virtualNetworks/subnets/join/action`
  - `Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action`
  - `Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action`

### Microsoft.ContainerInstance/containerGroups
- **Uso**: Azure Container Instances
- **Actions**: `["Microsoft.Network/virtualNetworks/subnets/action"]`

### Microsoft.Databricks/workspaces
- **Uso**: Azure Databricks
- **Actions**:
  - `Microsoft.Network/virtualNetworks/subnets/join/action`
  - `Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action`
  - `Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action`

### Microsoft.AzureCosmosDB/clusters
- **Uso**: Cosmos DB
- **Actions**: `["Microsoft.Network/virtualNetworks/subnets/join/action"]`

### Microsoft.Netapp/volumes
- **Uso**: Azure NetApp Files
- **Actions**: `["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]`

## Vinculación con Route Tables

El módulo soporta dos formas de asociar route tables a las subnets:

### Método 1: Integración Automática (Recomendado)

Especifica el `route_table_id` directamente en la definición de la subnet. El módulo creará automáticamente la asociación.

```hcl
subnets = [
  {
    name           = "subnet-web"
    address_prefix = "10.10.1.0/24"
    route_table_id = module.route_table.rt_id
  }
]
```

### Método 2: Asociación Manual

Si prefieres gestionar las asociaciones fuera del módulo:

```hcl
resource "azurerm_subnet_route_table_association" "custom" {
  subnet_id      = module.vnet.subnet_ids["subnet-web"]
  route_table_id = module.route_table.rt_id
}
```

## Consideraciones de Seguridad

1. **Private Endpoints**: Establece `private_endpoint_network_policies_enabled = false` en subnets que hospedarán private endpoints
2. **Service Endpoints**: Úsalos para restringir el acceso a servicios de Azure solo desde subnets específicas
3. **Delegación**: Las subnets delegadas solo pueden usarse por el servicio delegado
4. **Route Tables**: Asegúrate de que las rutas no creen loops de enrutamiento
5. **Address Space**: Planifica cuidadosamente para evitar solapamiento con otras VNets

## Requisitos de Versión

| Componente | Versión |
|-----------|---------|
| Terraform | >= 1.0 |
| Provider azurerm | >= 3.0 |

## Autor

Desarrollado por el equipo de Xpertal DevOps

## Referencias

- [Azure Virtual Network Documentation](https://docs.microsoft.com/azure/virtual-network/)
- [Azure Service Endpoints](https://docs.microsoft.com/azure/virtual-network/virtual-network-service-endpoints-overview)
- [Azure Private Link](https://docs.microsoft.com/azure/private-link/)
- [Subnet Delegation](https://docs.microsoft.com/azure/virtual-network/subnet-delegation-overview)
