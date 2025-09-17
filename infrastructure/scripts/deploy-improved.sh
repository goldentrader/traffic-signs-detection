#!/bin/bash

# Improved Deployment Script - Containerized Architecture
# Addresses issues with VM-based deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="traffic-sign-detector"
ENVIRONMENT="${1:-prod}"
ARCHITECTURE="${2:-containerized}"  # containerized, serverless, hybrid
TERRAFORM_DIR="architecture/${ARCHITECTURE}"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites for ${ARCHITECTURE} architecture..."
    
    # Check if required tools are installed
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform is required but not installed. Aborting."; exit 1; }
    command -v az >/dev/null 2>&1 || { log_error "Azure CLI is required but not installed. Aborting."; exit 1; }
    command -v docker >/dev/null 2>&1 || { log_error "Docker is required but not installed. Aborting."; exit 1; }
    
    # Check if terraform.tfvars exists
    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        log_error "terraform.tfvars not found in $TERRAFORM_DIR. Please copy terraform.tfvars.example and configure it."
        exit 1
    fi
    
    # Check Azure login
    if ! az account show >/dev/null 2>&1; then
        log_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

deploy_infrastructure() {
    log_info "Deploying ${ARCHITECTURE} infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying Terraform deployment..."
    terraform apply tfplan
    
    # Get outputs
    log_info "Getting Terraform outputs..."
    if [ "$ARCHITECTURE" = "containerized" ]; then
        BACKEND_URL=$(terraform output -raw backend_container_app_url)
        FRONTEND_URL=$(terraform output -raw frontend_container_app_url)
        FRONT_DOOR_URL=$(terraform output -raw front_door_url)
        CONTAINER_REGISTRY=$(terraform output -raw container_registry_login_server)
    elif [ "$ARCHITECTURE" = "serverless" ]; then
        BACKEND_URL=$(terraform output -raw function_app_url)
        FRONTEND_URL=$(terraform output -raw static_web_app_url)
        FRONT_DOOR_URL=$(terraform output -raw front_door_url)
    fi
    
    cd - > /dev/null
    
    log_success "Infrastructure deployed successfully"
    log_info "Backend URL: $BACKEND_URL"
    log_info "Frontend URL: $FRONTEND_URL"
    log_info "Front Door URL: $FRONT_DOOR_URL"
}

build_and_push_images() {
    if [ "$ARCHITECTURE" = "containerized" ]; then
        log_info "Building and pushing container images..."
        
        # Build backend image
        log_info "Building backend image..."
        docker build -f Dockerfile.multi-stage --target production -t "$CONTAINER_REGISTRY/traffic-sign-detector:latest" .
        
        # Build frontend image
        log_info "Building frontend image..."
        docker build -f Dockerfile.multi-stage --target frontend -t "$CONTAINER_REGISTRY/traffic-sign-detector-frontend:latest" .
        
        # Push images
        log_info "Pushing images to container registry..."
        docker push "$CONTAINER_REGISTRY/traffic-sign-detector:latest"
        docker push "$CONTAINER_REGISTRY/traffic-sign-detector-frontend:latest"
        
        log_success "Images built and pushed successfully"
    fi
}

deploy_application() {
    log_info "Deploying application..."
    
    if [ "$ARCHITECTURE" = "containerized" ]; then
        # Update container apps with new images
        log_info "Updating container apps..."
        
        # Update backend container app
        az containerapp update \
            --name "${PROJECT_NAME}-backend" \
            --resource-group "${PROJECT_NAME}-${ENVIRONMENT}-rg" \
            --image "$CONTAINER_REGISTRY/traffic-sign-detector:latest"
        
        # Update frontend container app
        az containerapp update \
            --name "${PROJECT_NAME}-frontend" \
            --resource-group "${PROJECT_NAME}-${ENVIRONMENT}-rg" \
            --image "$CONTAINER_REGISTRY/traffic-sign-detector-frontend:latest"
        
        # Run database migrations
        log_info "Running database migrations..."
        az containerapp exec \
            --name "${PROJECT_NAME}-backend" \
            --resource-group "${PROJECT_NAME}-${ENVIRONMENT}-rg" \
            --command "python manage.py migrate"
        
    elif [ "$ARCHITECTURE" = "serverless" ]; then
        # Deploy to Azure Functions
        log_info "Deploying to Azure Functions..."
        
        # Build and deploy function app
        cd backend
        func azure functionapp publish "${PROJECT_NAME}-backend-$(terraform output -raw suffix)"
        cd ..
        
        # Deploy static web app
        log_info "Deploying static web app..."
        cd frontend
        npm run build
        az staticwebapp deploy \
            --name "${PROJECT_NAME}-frontend-$(terraform output -raw suffix)" \
            --resource-group "${PROJECT_NAME}-${ENVIRONMENT}-rg" \
            --source-location . \
            --app-location ./build
        cd ..
    fi
    
    log_success "Application deployed successfully"
}

run_health_checks() {
    log_info "Running health checks..."
    
    # Wait for deployment to be ready
    sleep 30
    
    # Check backend health
    if curl -f "$BACKEND_URL/admin/" >/dev/null 2>&1; then
        log_success "Backend health check passed"
    else
        log_error "Backend health check failed"
        return 1
    fi
    
    # Check frontend health
    if curl -f "$FRONTEND_URL" >/dev/null 2>&1; then
        log_success "Frontend health check passed"
    else
        log_error "Frontend health check failed"
        return 1
    fi
    
    # Check API endpoint
    if curl -f "$BACKEND_URL/api/global-stats/" >/dev/null 2>&1; then
        log_success "API health check passed"
    else
        log_error "API health check failed"
        return 1
    fi
}

setup_monitoring() {
    log_info "Setting up monitoring and alerting..."
    
    # Create Application Insights alerts
    az monitor metrics alert create \
        --name "${PROJECT_NAME}-high-cpu" \
        --resource-group "${PROJECT_NAME}-${ENVIRONMENT}-rg" \
        --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${PROJECT_NAME}-${ENVIRONMENT}-rg" \
        --condition "avg Percentage CPU > 80" \
        --description "High CPU usage alert" \
        --evaluation-frequency 1m \
        --window-size 5m \
        --severity 2
    
    # Create log analytics alerts
    az monitor scheduled-query create \
        --name "${PROJECT_NAME}-error-rate" \
        --resource-group "${PROJECT_NAME}-${ENVIRONMENT}-rg" \
        --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${PROJECT_NAME}-${ENVIRONMENT}-rg" \
        --condition "count 'traces' | where severityLevel >= 3 | summarize count() by bin(timestamp, 5m) | where count_ > 10" \
        --description "High error rate alert" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 2
    
    log_success "Monitoring and alerting configured"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f "$TERRAFORM_DIR/tfplan"
    rm -f "*.log"
}

show_deployment_summary() {
    log_success "Deployment completed successfully!"
    echo ""
    echo "=================================="
    echo "🚀 Deployment Summary"
    echo "=================================="
    echo "Architecture: $ARCHITECTURE"
    echo "Environment: $ENVIRONMENT"
    echo "Backend URL: $BACKEND_URL"
    echo "Frontend URL: $FRONTEND_URL"
    echo "Front Door URL: $FRONT_DOOR_URL"
    echo ""
    echo "📊 Next Steps:"
    echo "1. Test the application endpoints"
    echo "2. Configure custom domain (if needed)"
    echo "3. Set up monitoring dashboards"
    echo "4. Configure backup policies"
    echo ""
    echo "🔧 Management Commands:"
    echo "• View logs: az monitor app-insights query --app $PROJECT_NAME-insights"
    echo "• Scale app: az containerapp update --name $PROJECT_NAME-backend --min-replicas 2"
    echo "• Update app: ./deploy-improved.sh $ENVIRONMENT $ARCHITECTURE"
    echo "=================================="
}

# Main execution
main() {
    log_info "Starting improved deployment for environment: $ENVIRONMENT"
    log_info "Architecture: $ARCHITECTURE"
    
    # Load environment variables
    if [ -f ".env" ]; then
        source .env
    else
        log_warning ".env file not found. Make sure environment variables are set."
    fi
    
    check_prerequisites
    deploy_infrastructure
    build_and_push_images
    deploy_application
    run_health_checks
    setup_monitoring
    cleanup
    show_deployment_summary
}

# Handle script interruption
trap cleanup EXIT

# Validate arguments
if [ "$ARCHITECTURE" != "containerized" ] && [ "$ARCHITECTURE" != "serverless" ] && [ "$ARCHITECTURE" != "hybrid" ]; then
    log_error "Invalid architecture. Use: containerized, serverless, or hybrid"
    echo "Usage: $0 [environment] [architecture]"
    echo "  environment: dev, staging, prod (default: prod)"
    echo "  architecture: containerized, serverless, hybrid (default: containerized)"
    exit 1
fi

# Run main function
main "$@"
