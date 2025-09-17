#!/bin/bash

# Secure Deployment Script - Handles secrets without exposing them
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
ARCHITECTURE="${2:-containerized}"
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

# Check if secrets are properly configured
check_secrets() {
    log_info "Checking secret configuration..."
    
    # Check if .env.secure exists
    if [ ! -f ".env.secure" ]; then
        log_error ".env.secure file not found!"
        log_info "Please copy .env.secure.example to .env.secure and configure your secrets:"
        log_info "cp .env.secure.example .env.secure"
        log_info "Then edit .env.secure with your actual values"
        exit 1
    fi
    
    # Load environment variables
    source .env.secure
    
    # Check required secrets
    local missing_secrets=()
    
    if [ -z "$TF_VAR_db_admin_password" ]; then
        missing_secrets+=("TF_VAR_db_admin_password")
    fi
    
    if [ -z "$TF_VAR_django_secret_key" ]; then
        missing_secrets+=("TF_VAR_django_secret_key")
    fi
    
    if [ -z "$TF_VAR_redis_password" ]; then
        missing_secrets+=("TF_VAR_redis_password")
    fi
    
    if [ -z "$TF_VAR_jwt_secret" ]; then
        missing_secrets+=("TF_VAR_jwt_secret")
    fi
    
    if [ ${#missing_secrets[@]} -ne 0 ]; then
        log_error "Missing required secrets:"
        for secret in "${missing_secrets[@]}"; do
            log_error "  - $secret"
        done
        log_info "Please update .env.secure with all required values"
        exit 1
    fi
    
    log_success "All required secrets are configured"
}

# Generate secure passwords if not provided
generate_secrets() {
    log_info "Generating secure passwords for missing secrets..."
    
    # Generate Django secret key if not provided
    if [ -z "$TF_VAR_django_secret_key" ]; then
        TF_VAR_django_secret_key=$(openssl rand -base64 64)
        log_info "Generated Django secret key"
    fi
    
    # Generate JWT secret if not provided
    if [ -z "$TF_VAR_jwt_secret" ]; then
        TF_VAR_jwt_secret=$(openssl rand -base64 32)
        log_info "Generated JWT secret"
    fi
    
    # Generate database password if not provided
    if [ -z "$TF_VAR_db_admin_password" ]; then
        TF_VAR_db_admin_password=$(openssl rand -base64 32)
        log_info "Generated database password"
    fi
    
    # Generate Redis password if not provided
    if [ -z "$TF_VAR_redis_password" ]; then
        TF_VAR_redis_password=$(openssl rand -base64 32)
        log_info "Generated Redis password"
    fi
    
    # Export generated secrets
    export TF_VAR_django_secret_key
    export TF_VAR_jwt_secret
    export TF_VAR_db_admin_password
    export TF_VAR_redis_password
}

# Deploy infrastructure with secure secrets
deploy_infrastructure() {
    log_info "Deploying infrastructure with secure secret management..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying Terraform deployment..."
    terraform apply tfplan
    
    # Get Key Vault URI
    KEY_VAULT_URI=$(terraform output -raw key_vault_uri)
    log_success "Key Vault created: $KEY_VAULT_URI"
    
    cd - > /dev/null
}

# Store secrets in Key Vault
store_secrets() {
    log_info "Storing secrets in Azure Key Vault..."
    
    # Get Key Vault name from Terraform output
    cd "$TERRAFORM_DIR"
    KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
    cd - > /dev/null
    
    # Store secrets in Key Vault
    az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "database-password" --value "$TF_VAR_db_admin_password"
    az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "django-secret-key" --value "$TF_VAR_django_secret_key"
    az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "redis-password" --value "$TF_VAR_redis_password"
    az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "jwt-secret" --value "$TF_VAR_jwt_secret"
    
    log_success "Secrets stored in Key Vault"
}

# Update application configuration to use Key Vault
update_app_config() {
    log_info "Updating application configuration to use Key Vault..."
    
    # Get Key Vault URI
    cd "$TERRAFORM_DIR"
    KEY_VAULT_URI=$(terraform output -raw key_vault_uri)
    cd - > /dev/null
    
    # Update container app configuration
    az containerapp update \
        --name "${PROJECT_NAME}-backend" \
        --resource-group "${PROJECT_NAME}-${ENVIRONMENT}-rg" \
        --set-env-vars \
            "KEY_VAULT_URI=$KEY_VAULT_URI" \
            "USE_KEY_VAULT=true"
    
    log_success "Application configuration updated"
}

# Verify secret access
verify_secrets() {
    log_info "Verifying secret access..."
    
    # Get Key Vault name
    cd "$TERRAFORM_DIR"
    KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
    cd - > /dev/null
    
    # Test secret retrieval
    if az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "database-password" >/dev/null 2>&1; then
        log_success "Database password accessible"
    else
        log_error "Database password not accessible"
        return 1
    fi
    
    if az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "django-secret-key" >/dev/null 2>&1; then
        log_success "Django secret key accessible"
    else
        log_error "Django secret key not accessible"
        return 1
    fi
    
    log_success "All secrets are accessible"
}

# Clean up sensitive data
cleanup() {
    log_info "Cleaning up sensitive data..."
    
    # Unset environment variables
    unset TF_VAR_db_admin_password
    unset TF_VAR_django_secret_key
    unset TF_VAR_redis_password
    unset TF_VAR_jwt_secret
    
    # Remove temporary files
    rm -f "$TERRAFORM_DIR/tfplan"
    rm -f "*.log"
    
    log_success "Cleanup completed"
}

# Show deployment summary
show_summary() {
    log_success "Secure deployment completed!"
    echo ""
    echo "=================================="
    echo "🔐 Secure Deployment Summary"
    echo "=================================="
    echo "Architecture: $ARCHITECTURE"
    echo "Environment: $ENVIRONMENT"
    echo "Key Vault: $KEY_VAULT_URI"
    echo ""
    echo "✅ Secrets stored securely in Azure Key Vault"
    echo "✅ No secrets exposed in Terraform code"
    echo "✅ Application configured to use Key Vault"
    echo ""
    echo "🔧 Management Commands:"
    echo "• List secrets: az keyvault secret list --vault-name $KEY_VAULT_NAME"
    echo "• Get secret: az keyvault secret show --vault-name $KEY_VAULT_NAME --name <secret-name>"
    echo "• Update secret: az keyvault secret set --vault-name $KEY_VAULT_NAME --name <secret-name> --value <new-value>"
    echo "=================================="
}

# Main execution
main() {
    log_info "Starting secure deployment for environment: $ENVIRONMENT"
    log_info "Architecture: $ARCHITECTURE"
    
    check_secrets
    generate_secrets
    deploy_infrastructure
    store_secrets
    update_app_config
    verify_secrets
    cleanup
    show_summary
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
