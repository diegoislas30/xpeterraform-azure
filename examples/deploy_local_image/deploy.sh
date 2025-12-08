#!/bin/bash
# Script de deployment para portal_costos_cloud
# Este script automatiza el proceso de deployment a Azure

set -e  # Exit on error

# Colors para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para print con color
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"
}

# Verificar prerrequisitos
check_prerequisites() {
    print_header "Verificando prerrequisitos"

    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        exit 1
    fi
    print_success "Docker está instalado"

    # Verificar Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI no está instalado"
        exit 1
    fi
    print_success "Azure CLI está instalado"

    # Verificar Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform no está instalado"
        exit 1
    fi
    print_success "Terraform está instalado"

    # Verificar Azure login
    if ! az account show &> /dev/null; then
        print_error "No estás logueado en Azure. Ejecuta: az login"
        exit 1
    fi
    print_success "Logueado en Azure"

    # Verificar que la imagen local existe
    if ! docker images | grep -q "portal_costos_cloud-1-portal-costos"; then
        print_error "Imagen 'portal_costos_cloud-1-portal-costos' no encontrada localmente"
        print_info "Imágenes disponibles:"
        docker images
        exit 1
    fi
    print_success "Imagen local encontrada"
}

# Paso 1: Crear infraestructura
create_infrastructure() {
    print_header "Paso 1: Creando infraestructura en Azure"

    print_info "Inicializando Terraform..."
    terraform init

    print_info "Aplicando configuración Terraform..."
    terraform apply -auto-approve

    print_success "Infraestructura creada exitosamente"
}

# Paso 2: Push de imagen a ACR
push_image_to_acr() {
    print_header "Paso 2: Subiendo imagen a Azure Container Registry"

    # Obtener valores de Terraform
    ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
    ACR_NAME=$(terraform output -raw acr_name)

    print_info "ACR Login Server: $ACR_LOGIN_SERVER"
    print_info "ACR Name: $ACR_NAME"

    # Login a ACR
    print_info "Haciendo login a ACR..."
    az acr login --name "$ACR_NAME"
    print_success "Login exitoso"

    # Tagear imagen
    print_info "Tageando imagen local..."
    docker tag portal_costos_cloud-1-portal-costos:latest \
        "$ACR_LOGIN_SERVER/portal_costos_cloud:latest"
    print_success "Imagen tageada"

    # Push a ACR
    print_info "Subiendo imagen a ACR (esto puede tardar varios minutos)..."
    docker push "$ACR_LOGIN_SERVER/portal_costos_cloud:latest"
    print_success "Imagen subida exitosamente"

    # Verificar
    print_info "Verificando imagen en ACR..."
    az acr repository show \
        --name "$ACR_NAME" \
        --repository portal_costos_cloud
    print_success "Imagen verificada en ACR"
}

# Paso 3: Reiniciar container
restart_container() {
    print_header "Paso 3: Reiniciando Container Instance"

    # Obtener valores
    CONTAINER_NAME=$(terraform output -json | jq -r '.container_instance.value.container_group_name // "ci-portal-costos-dev"')
    RG_NAME=$(terraform output -json | jq -r '.azurerm_resource_group.value.name // "rg-portal-costos-dev"')

    # Si no tenemos el nombre, usar valores por defecto
    if [ "$CONTAINER_NAME" == "null" ] || [ -z "$CONTAINER_NAME" ]; then
        CONTAINER_NAME="ci-portal-costos-dev"
    fi
    if [ "$RG_NAME" == "null" ] || [ -z "$RG_NAME" ]; then
        RG_NAME="rg-portal-costos-dev"
    fi

    print_info "Container: $CONTAINER_NAME"
    print_info "Resource Group: $RG_NAME"

    print_info "Reiniciando container..."
    az container restart \
        --name "$CONTAINER_NAME" \
        --resource-group "$RG_NAME"
    print_success "Container reiniciado"

    # Esperar un poco
    print_info "Esperando que el container inicie (30 segundos)..."
    sleep 30
}

# Paso 4: Verificar deployment
verify_deployment() {
    print_header "Paso 4: Verificando deployment"

    CONTAINER_NAME=$(terraform output -json | jq -r '.container_instance.value.container_group_name // "ci-portal-costos-dev"')
    RG_NAME=$(terraform output -json | jq -r '.azurerm_resource_group.value.name // "rg-portal-costos-dev"')

    # Ver estado
    print_info "Estado del container:"
    az container show \
        --name "$CONTAINER_NAME" \
        --resource-group "$RG_NAME" \
        --query "{Name:name, State:instanceView.state, IP:ipAddress.ip, FQDN:ipAddress.fqdn}" \
        -o table

    # Ver logs
    print_info "Últimas líneas de logs:"
    az container logs \
        --name "$CONTAINER_NAME" \
        --resource-group "$RG_NAME" \
        --tail 20

    # URL de acceso
    CONTAINER_URL=$(terraform output -raw container_url 2>/dev/null || echo "")
    if [ -n "$CONTAINER_URL" ]; then
        print_success "Deployment completado!"
        echo ""
        print_info "Tu aplicación está disponible en:"
        echo -e "${GREEN}${CONTAINER_URL}${NC}"
        echo ""
        print_info "Puedes acceder desde tu navegador o con curl:"
        echo -e "${YELLOW}curl $CONTAINER_URL${NC}"
    fi
}

# Mostrar ayuda
show_help() {
    echo "Uso: ./deploy.sh [opción]"
    echo ""
    echo "Opciones:"
    echo "  full        - Deployment completo (crear infra + push + restart)"
    echo "  infra       - Solo crear infraestructura"
    echo "  push        - Solo push de imagen a ACR"
    echo "  restart     - Solo reiniciar container"
    echo "  verify      - Solo verificar estado"
    echo "  update      - Solo push + restart (para actualizaciones)"
    echo "  logs        - Ver logs del container"
    echo "  destroy     - Destruir toda la infraestructura"
    echo "  help        - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./deploy.sh full       # Primera vez"
    echo "  ./deploy.sh update     # Actualizar app"
    echo "  ./deploy.sh logs       # Ver logs"
}

# Ver logs
show_logs() {
    print_header "Logs del Container"

    CONTAINER_NAME=$(terraform output -json | jq -r '.container_instance.value.container_group_name // "ci-portal-costos-dev"')
    RG_NAME=$(terraform output -json | jq -r '.azurerm_resource_group.value.name // "rg-portal-costos-dev"')

    print_info "Mostrando logs de $CONTAINER_NAME..."
    az container logs \
        --name "$CONTAINER_NAME" \
        --resource-group "$RG_NAME" \
        --follow
}

# Destruir infraestructura
destroy_infrastructure() {
    print_header "Destruyendo infraestructura"

    print_warning "Esto eliminará todos los recursos en Azure"
    read -p "¿Estás seguro? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "Operación cancelada"
        exit 0
    fi

    print_info "Destruyendo recursos..."
    terraform destroy -auto-approve

    print_success "Recursos destruidos"
}

# Main
main() {
    case "${1:-help}" in
        full)
            check_prerequisites
            create_infrastructure
            push_image_to_acr
            restart_container
            verify_deployment
            ;;
        infra)
            check_prerequisites
            create_infrastructure
            ;;
        push)
            check_prerequisites
            push_image_to_acr
            ;;
        restart)
            restart_container
            ;;
        verify)
            verify_deployment
            ;;
        update)
            print_info "Actualizando aplicación..."
            check_prerequisites
            push_image_to_acr
            restart_container
            verify_deployment
            ;;
        logs)
            show_logs
            ;;
        destroy)
            destroy_infrastructure
            ;;
        help|*)
            show_help
            ;;
    esac
}

# Ejecutar
main "$@"
