# Containerized Architecture Deployment Guide

## Prerequisites
✅ Azure CLI installed (v2.77.0)
✅ Terraform installed (v1.13.2)
✅ Secure environment file created (.env.secure)

## Step 1: Azure Authentication
You need to authenticate with Azure before deployment:

```bash
az login
```

This will open a browser window for authentication. After successful login, you can verify with:
```bash
az account show
```

## Step 2: Set Azure Subscription (if multiple subscriptions)
If you have multiple Azure subscriptions, set the active one:
```bash
az account list --output table
az account set --subscription "Your-Subscription-Name"
```

## Step 3: Deploy Infrastructure
Run the secure deployment script:
```bash
chmod +x infrastructure/scripts/deploy-secure.sh
./infrastructure/scripts/deploy-secure.sh prod containerized
```

## What This Will Deploy

### Azure Resources:
- **Resource Group**: traffic-sign-detector-prod-rg
- **Container Registry**: Premium tier with private networking
- **Container Apps Environment**: Isolated network environment
- **Backend Container App**: Django application with auto-scaling
- **Frontend Container App**: React application
- **PostgreSQL Flexible Server**: Managed database with high availability
- **Redis Cache**: Premium tier for WebSocket channels
- **Key Vault**: Secure secret storage
- **Front Door**: CDN with WAF protection
- **Application Insights**: Monitoring and logging

### Security Features:
- All secrets stored in Azure Key Vault
- Private networking for all services
- WAF protection with rate limiting
- TLS encryption for all communications
- Managed identities for service authentication

### Estimated Costs:
- Container Apps: ~$50-100/month (depending on usage)
- PostgreSQL: ~$100-200/month (GP_Standard_D2s_v3)
- Redis: ~$50-100/month (Premium tier)
- Container Registry: ~$20/month (Premium)
- Front Door: ~$10-50/month (depending on traffic)
- **Total**: ~$230-470/month

## Step 4: Build and Push Docker Images
After infrastructure deployment, build and push your application images:

```bash
# Get container registry login server
cd architecture/containerized
ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)
cd ../..

# Login to container registry
az acr login --name $(echo $ACR_LOGIN_SERVER | cut -d'.' -f1)

# Build and push backend image
docker build -t $ACR_LOGIN_SERVER/traffic-sign-detector:latest .
docker push $ACR_LOGIN_SERVER/traffic-sign-detector:latest

# Build and push frontend image (if separate)
# docker build -f Dockerfile.frontend -t $ACR_LOGIN_SERVER/traffic-sign-detector-frontend:latest .
# docker push $ACR_LOGIN_SERVER/traffic-sign-detector-frontend:latest
```

## Step 5: Access Your Application
After deployment, get your application URLs:
```bash
cd architecture/containerized
echo "Frontend URL: $(terraform output -raw frontend_container_app_url)"
echo "Backend URL: $(terraform output -raw backend_container_app_url)"
echo "Front Door URL: $(terraform output -raw front_door_url)"
```

## Monitoring and Management
- **Application Insights**: Monitor application performance
- **Log Analytics**: Centralized logging
- **Key Vault**: Manage secrets securely
- **Container Apps**: Monitor container health and scaling

## Cleanup (if needed)
To destroy all resources:
```bash
cd architecture/containerized
terraform destroy
```

## Troubleshooting
- Check Azure portal for resource status
- Review Application Insights logs
- Verify Key Vault access policies
- Check container app logs in Azure portal
