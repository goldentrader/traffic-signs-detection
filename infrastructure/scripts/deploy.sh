#!/bin/bash

# Traffic Sign Detection System - Deployment Script

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
TERRAFORM_DIR="infrastructure/terraform"
ANSIBLE_DIR="infrastructure/ansible"

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
    log_info "Checking prerequisites..."
    
    # Check if required tools are installed
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform is required but not installed. Aborting."; exit 1; }
    command -v ansible >/dev/null 2>&1 || { log_error "Ansible is required but not installed. Aborting."; exit 1; }
    command -v az >/dev/null 2>&1 || { log_error "Azure CLI is required but not installed. Aborting."; exit 1; }
    
    # Check if terraform.tfvars exists
    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        log_error "terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
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
    VM_PUBLIC_IP=$(terraform output -raw vm_public_ip)
    POSTGRESQL_SERVER_FQDN=$(terraform output -raw postgresql_server_fqdn)
    REDIS_CACHE_HOSTNAME=$(terraform output -raw redis_cache_hostname)
    
    cd - > /dev/null
    
    log_success "Infrastructure deployed successfully"
    log_info "VM Public IP: $VM_PUBLIC_IP"
    log_info "PostgreSQL Server: $POSTGRESQL_SERVER_FQDN"
    log_info "Redis Cache: $REDIS_CACHE_HOSTNAME"
}

deploy_application() {
    log_info "Deploying application with Ansible..."
    
    # Create inventory file
    cat > inventory.ini << INVENTORY_EOF
[all]
$VM_PUBLIC_IP ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/id_rsa
INVENTORY_EOF
    
    # Run Ansible playbook
    ansible-playbook -i inventory.ini "$ANSIBLE_DIR/playbook.yml" \
        -e "vm_public_ip=$VM_PUBLIC_IP" \
        -e "postgresql_server_fqdn=$POSTGRESQL_SERVER_FQDN" \
        -e "redis_cache_hostname=$REDIS_CACHE_HOSTNAME" \
        -e "db_admin_username=postgres" \
        -e "db_admin_password=$DB_ADMIN_PASSWORD" \
        -e "django_secret_key=$DJANGO_SECRET_KEY" \
        -e "django_admin_password=$DJANGO_ADMIN_PASSWORD" \
        -e "redis_password=$REDIS_PASSWORD" \
        -e "email_host_user=$EMAIL_HOST_USER" \
        -e "email_host_password=$EMAIL_HOST_PASSWORD" \
        -e "default_from_email=$DEFAULT_FROM_EMAIL" \
        -e "storage_account_name=$STORAGE_ACCOUNT_NAME" \
        -e "storage_account_key=$STORAGE_ACCOUNT_KEY" \
        -e "application_insights_connection_string=$APPLICATION_INSIGHTS_CONNECTION_STRING"
    
    log_success "Application deployed successfully"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f inventory.ini
    rm -f "$TERRAFORM_DIR/tfplan"
}

# Main execution
main() {
    log_info "Starting deployment for environment: $ENVIRONMENT"
    
    # Load environment variables
    if [ -f ".env" ]; then
        source .env
    else
        log_warning ".env file not found. Make sure environment variables are set."
    fi
    
    check_prerequisites
    deploy_infrastructure
    deploy_application
    cleanup
    
    log_success "Deployment completed successfully!"
    log_info "Application URL: http://$VM_PUBLIC_IP"
    log_info "Admin Panel: http://$VM_PUBLIC_IP/admin"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"
