# 🚀 Traffic Sign Detection System - Deployment Guide

This guide provides step-by-step instructions for deploying the Traffic Sign Detection System to Azure using Infrastructure as Code (IaC) and CI/CD pipelines.

## 📋 Prerequisites

### Required Tools

1. **Azure CLI** - [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Terraform** - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
3. **Ansible** - [Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
4. **Docker** - [Installation Guide](https://docs.docker.com/get-docker/)
5. **Git** - [Installation Guide](https://git-scm.com/downloads)

### Azure Requirements

- Azure subscription with sufficient permissions
- Resource group creation permissions
- Service principal for automation (optional but recommended)

## 🔧 Initial Setup

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd yolo
```

### 2. Install Development Environment

```bash
# Run the automated setup script
./infrastructure/scripts/setup-dev-environment.sh
```

### 3. Configure Azure CLI

```bash
# Login to Azure
az login

# Set default subscription (optional)
az account set --subscription "Your Subscription ID"

# Create service principal for automation (optional)
az ad sp create-for-rbac --name "traffic-sign-detector-sp" --role contributor --scopes /subscriptions/{subscription-id}
```

### 4. Generate SSH Key

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/traffic-sign-detector

# Add to SSH agent
ssh-add ~/.ssh/traffic-sign-detector
```

## 🏗️ Infrastructure Deployment

### 1. Configure Terraform

```bash
cd infrastructure/terraform

# Copy and edit variables file
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
project_name = "traffic-sign-detector"
environment  = "prod"
location     = "East US"
vm_size      = "Standard_D4s_v3"
admin_username = "azureuser"

# Your SSH public key
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... your-email@example.com"

# Database credentials
db_admin_username = "postgres"
db_admin_password = "YourSecurePassword123!"

# Django secret key (generate with: python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
django_secret_key = "your-django-secret-key-here"

# Optional: Domain configuration
domain_name = "your-domain.com"
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply deployment
terraform apply tfplan
```

### 3. Get Deployment Outputs

```bash
# Get important outputs
terraform output vm_public_ip
terraform output postgresql_server_fqdn
terraform output redis_cache_hostname
```

## 🚀 Application Deployment

### 1. Configure Ansible

```bash
cd ../ansible

# Copy and edit inventory file
cp inventory.ini.example inventory.ini
```

Edit `inventory.ini` with your server details:

```ini
[all]
your-vm-public-ip ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/traffic-sign-detector
```

### 2. Create Environment File

Create `.env` file in project root:

```bash
# Database
DB_ADMIN_PASSWORD=YourSecurePassword123!
DATABASE_NAME=traffic_sign_detector

# Django
DJANGO_SECRET_KEY=your-django-secret-key-here
DJANGO_ADMIN_PASSWORD=admin123

# Redis
REDIS_PASSWORD=your-redis-password

# Email (optional)
EMAIL_HOST_USER=your-email@example.com
EMAIL_HOST_PASSWORD=your-email-password
DEFAULT_FROM_EMAIL=noreply@trafficsigndetector.com

# Azure Storage
STORAGE_ACCOUNT_NAME=your-storage-account-name
STORAGE_ACCOUNT_KEY=your-storage-account-key

# Application Insights
APPLICATION_INSIGHTS_CONNECTION_STRING=your-connection-string
```

### 3. Deploy Application

```bash
# Run the deployment script
./infrastructure/scripts/deploy.sh
```

Or manually:

```bash
# Run Ansible playbook
ansible-playbook -i inventory.ini playbook.yml \
  -e "vm_public_ip=YOUR_VM_IP" \
  -e "postgresql_server_fqdn=YOUR_DB_FQDN" \
  -e "redis_cache_hostname=YOUR_REDIS_HOSTNAME" \
  -e "db_admin_password=YourSecurePassword123!" \
  -e "django_secret_key=your-django-secret-key" \
  -e "django_admin_password=admin123"
```

## 🔄 CI/CD Pipeline Setup

### 1. GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

```
# Azure Credentials
AZURE_CREDENTIALS={"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}

# Terraform State
TF_STATE_RG=terraform-state-rg
TF_STATE_SA=terraformstate123
TF_STATE_CONTAINER=tfstate

# SSH Keys
SSH_PUBLIC_KEY=ssh-rsa AAAAB3NzaC1yc2E...
SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...

# Database
DB_ADMIN_PASSWORD=YourSecurePassword123!
DB_ADMIN_USERNAME=postgres

# Django
DJANGO_SECRET_KEY=your-django-secret-key
DJANGO_ADMIN_PASSWORD=admin123

# Redis
REDIS_PASSWORD=your-redis-password

# Email
EMAIL_HOST_USER=your-email@example.com
EMAIL_HOST_PASSWORD=your-email-password
DEFAULT_FROM_EMAIL=noreply@trafficsigndetector.com

# Azure Storage
STORAGE_ACCOUNT_NAME=your-storage-account
STORAGE_ACCOUNT_KEY=your-storage-key

# Application Insights
APPLICATION_INSIGHTS_CONNECTION_STRING=your-connection-string

# Container Registry
ACR_LOGIN_SERVER=your-registry.azurecr.io
ACR_USERNAME=your-registry-username
ACR_PASSWORD=your-registry-password

# Slack (optional)
SLACK_WEBHOOK=https://hooks.slack.com/services/...
```

### 2. Enable GitHub Actions

The CI/CD pipeline is automatically enabled when you push to the `main` branch. The pipeline will:

1. Run tests and security scans
2. Build Docker images
3. Deploy infrastructure with Terraform
4. Deploy application with Ansible
5. Send notifications

## 🔍 Verification and Testing

### 1. Check Application Status

```bash
# Check if application is running
curl -I http://YOUR_VM_IP/admin/

# Check API endpoint
curl http://YOUR_VM_IP/api/global-stats/

# Check WebSocket connection
# Use a WebSocket client to connect to ws://YOUR_VM_IP/ws/detect/
```

### 2. Monitor System Health

```bash
# Run monitoring script
./infrastructure/scripts/monitor.sh

# Check specific services
./infrastructure/scripts/monitor.sh health
```

### 3. Access Application

- **Main Application**: `http://YOUR_VM_IP`
- **Admin Panel**: `http://YOUR_VM_IP/admin`
- **API Documentation**: `http://YOUR_VM_IP/api/`

Default admin credentials:
- Username: `admin`
- Password: `admin123` (or your configured password)

## 🛠️ Maintenance and Operations

### Regular Maintenance

```bash
# Create database backup
./infrastructure/scripts/monitor.sh backup

# Clean up old logs
./infrastructure/scripts/monitor.sh cleanup

# Restart services if needed
./infrastructure/scripts/monitor.sh restart
```

### Scaling Operations

#### Vertical Scaling (Increase VM Size)

1. Update `terraform.tfvars`:
   ```hcl
   vm_size = "Standard_D8s_v3"  # Increase from D4s_v3
   ```

2. Apply changes:
   ```bash
   terraform plan
   terraform apply
   ```

#### Horizontal Scaling (Multiple VMs)

1. Update Terraform configuration to use Azure Load Balancer
2. Configure multiple VMs in the same availability set
3. Update Ansible inventory with multiple servers

### SSL Certificate Setup

For production with SSL:

1. Obtain SSL certificate (Let's Encrypt recommended)
2. Update `terraform.tfvars`:
   ```hcl
   domain_name = "your-domain.com"
   ssl_certificate_path = "/path/to/certificate.crt"
   ssl_private_key_path = "/path/to/private.key"
   ```
3. Redeploy with updated configuration

## 🆘 Troubleshooting

### Common Issues

#### 1. SSH Connection Failed

```bash
# Check security group rules
az network nsg rule list --resource-group traffic-sign-detector-prod-rg --nsg-name traffic-sign-detector-nsg

# Verify VM is running
az vm show --resource-group traffic-sign-detector-prod-rg --name traffic-sign-detector-vm --show-details
```

#### 2. Database Connection Failed

```bash
# Check database server status
az postgres flexible-server show --resource-group traffic-sign-detector-prod-rg --name your-server-name

# Check firewall rules
az postgres flexible-server firewall-rule list --resource-group traffic-sign-detector-prod-rg --name your-server-name
```

#### 3. Application Not Starting

```bash
# SSH into the server
ssh azureuser@YOUR_VM_IP

# Check application logs
sudo tail -f /var/log/traffic-sign-detector.log

# Check service status
sudo systemctl status supervisor
sudo supervisorctl status
```

#### 4. CI/CD Pipeline Failures

1. Check GitHub Actions logs
2. Verify all secrets are configured correctly
3. Check Azure service principal permissions
4. Verify Terraform state is accessible

### Getting Help

1. Check application logs: `/var/log/traffic-sign-detector.log`
2. Check system logs: `/var/log/syslog`
3. Review Azure portal for resource status
4. Check GitHub Actions logs for CI/CD issues
5. Use monitoring script: `./infrastructure/scripts/monitor.sh`

## 📊 Monitoring and Alerting

### Application Insights

The system includes Application Insights for monitoring:

- Performance metrics
- Error tracking
- User analytics
- Custom telemetry

### Log Analytics

Centralized logging with Log Analytics:

- Application logs
- System logs
- Security logs
- Custom metrics

### Health Checks

Automated health checks:

- Application availability
- Database connectivity
- Redis connectivity
- System resources

## 🔒 Security Best Practices

1. **Regular Updates**: Keep all components updated
2. **SSL/TLS**: Use HTTPS in production
3. **Firewall**: Restrict access to necessary ports only
4. **Secrets**: Use Azure Key Vault for all secrets
5. **Monitoring**: Enable security monitoring and alerting
6. **Backups**: Regular database and configuration backups

## 📈 Performance Optimization

1. **Caching**: Use Redis for session and data caching
2. **CDN**: Use Azure CDN for static assets
3. **Database**: Optimize queries and use connection pooling
4. **Monitoring**: Monitor performance metrics and optimize bottlenecks

## 🎯 Next Steps

1. Set up monitoring and alerting
2. Configure SSL certificates
3. Set up automated backups
4. Implement horizontal scaling
5. Add additional security measures
6. Set up disaster recovery procedures

---

For additional support, please refer to the [Infrastructure README](infrastructure/README.md) or create an issue in the repository.
