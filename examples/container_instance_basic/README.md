# Ejemplo Básico - Azure Container Instance

Este ejemplo despliega un contenedor NGINX simple con acceso público y DNS.

## ¿Qué hace este ejemplo?

- Crea un Resource Group
- Despliega un contenedor NGINX con IP pública
- Configura un DNS label único
- Expone el puerto 80

## Uso

```bash
# Inicializar Terraform
terraform init

# Ver el plan
terraform plan

# Aplicar
terraform apply

# Ver la URL del contenedor
terraform output container_url
```

## Acceder al contenedor

Después del despliegue, puedes acceder a NGINX en:
```bash
# Usando la URL
curl http://$(terraform output -raw container_url)

# O usando el FQDN directamente
terraform output container_ip
```

## Limpiar recursos

```bash
terraform destroy
```

## Costo estimado

- **SKU**: Container Instance Linux, 1 vCPU, 1.5 GB RAM
- **Costo aproximado**: ~$0.0000125/segundo (~$32/mes si corre 24/7)

## Próximos pasos

- Ver `../acr_with_container_instance/` para usar imágenes privadas desde ACR
- Ver `../container_instance_advanced/` para múltiples contenedores
- Ver `../container_instance_with_volumes/` para persistencia de datos
