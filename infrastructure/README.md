# Traffic Sign Detection System - Infrastructure

This directory contains all the infrastructure as code (IaC) and deployment automation for the Traffic Sign Detection System.

## 📁 Directory Structure

```
infrastructure/
├── terraform/                 # Terraform infrastructure definitions
│   ├── main.tf               # Main infrastructure resources
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output definitions
│   └── terraform.tfvars.example # Example variables file
├── ansible/                  # Ansible configuration management
│   ├── playbook.yml          # Main deployment playbook
│   ├── templates/            # Jinja2 templates
│   │   ├── django_settings.py.j2
│   │   ├── .env.j2
│   │   ├── nginx.conf.j2
│   │   └── supervisor.conf.j2
│   ├── inventory.ini.example # Example inventory file
│   └── ansible.cfg           # Ansible configuration
└── scripts/                  # Deployment and maintenance scripts
    ├── deploy.sh             # Main deployment script
    ├── setup-dev-environment.sh # Development environment setup
    └── monitor.sh            # System monitoring script
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** - Install and configure with `az login`
2. **Terraform** - Install from [terraform.io](https://terraform.io)
3. **Ansible** - Install with `pip install ansible[azure]`
4. **SSH Key** - Generate with `ssh-keygen -t rsa -b 4096`

### 1. Configure Terraform

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Configure Ansible

```bash
cd infrastructure/ansible
cp inventory.ini.example inventory.ini
# Edit inventory.ini with your server details
```

### 3. Deploy Infrastructure

```bash
# From project root
./infrastructure/scripts/deploy.sh
```

## 🏗️ Infrastructure Components

### Azure Resources

- **Virtual Machine** - Ubuntu 20.04 LTS for application hosting
- **PostgreSQL Database** - Flexible server for data storage
- **Redis Cache** - For WebSocket channels and caching
- **Storage Account** - For static files and media
- **Container Registry** - For Docker images
- **Key Vault** - For secrets management
- **Application Insights** - For monitoring and logging
- **Log Analytics** - For centralized logging

### Network Security

- **Network Security Group** - Firewall rules
- **Virtual Network** - Isolated network environment
- **Public IP** - External access to the application

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root with the following variables:

```bash
# Database
DB_ADMIN_PASSWORD=your-secure-password
DATABASE_NAME=traffic_sign_detector

# Django
DJANGO_SECRET_KEY=your-django-secret-key
DJANGO_ADMIN_PASSWORD=your-admin-password

# Redis
REDIS_PASSWORD=your-redis-password

# Email (optional)
EMAIL_HOST_USER=your-email@example.com
EMAIL_HOST_PASSWORD=your-email-password
DEFAULT_FROM_EMAIL=noreply@trafficsigndetector.com

# Azure Storage
STORAGE_ACCOUNT_NAME=your-storage-account
STORAGE_ACCOUNT_KEY=your-storage-key

# Application Insights
APPLICATION_INSIGHTS_CONNECTION_STRING=your-connection-string
```

### Terraform Variables

Key variables in `terraform.tfvars`:

```hcl
project_name = "traffic-sign-detector"
environment  = "prod"
location     = "East US"
vm_size      = "Standard_D4s_v3"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
db_admin_password = "your-secure-password"
django_secret_key = "your-django-secret-key"
```

## 🚀 Deployment Process

### Automated Deployment (CI/CD)

The system uses GitHub Actions for automated deployment:

1. **Code Push** - Triggers CI/CD pipeline
2. **Testing** - Runs unit tests and security scans
3. **Build** - Creates Docker images
4. **Infrastructure** - Deploys Azure resources with Terraform
5. **Application** - Configures server with Ansible
6. **Monitoring** - Sets up monitoring and alerting

### Manual Deployment

```bash
# 1. Deploy infrastructure
cd infrastructure/terraform
terraform init
terraform plan
terraform apply

# 2. Deploy application
cd ../ansible
ansible-playbook -i inventory.ini playbook.yml
```

## 📊 Monitoring and Maintenance

### System Monitoring

```bash
# Check system health
./infrastructure/scripts/monitor.sh

# Create database backup
./infrastructure/scripts/monitor.sh backup

# Clean up old logs
./infrastructure/scripts/monitor.sh cleanup

# Restart services
./infrastructure/scripts/monitor.sh restart
```

### Log Locations

- **Application Logs**: `/var/log/traffic-sign-detector.log`
- **Django Logs**: `/var/log/django.log`
- **Nginx Logs**: `/var/log/nginx/`
- **System Logs**: `/var/log/syslog`

### Health Checks

- **Application**: `http://your-server/admin/`
- **API**: `http://your-server/api/global-stats/`
- **WebSocket**: `ws://your-server/ws/detect/`

## 🔒 Security

### SSL/TLS Configuration

For production with SSL:

1. Obtain SSL certificate (Let's Encrypt recommended)
2. Update `terraform.tfvars` with domain name
3. Configure SSL paths in Ansible templates
4. Redeploy with updated configuration

### Firewall Rules

- **Port 22** - SSH access
- **Port 80** - HTTP (redirects to HTTPS)
- **Port 443** - HTTPS
- **Port 8000** - Django (internal only)

### Secrets Management

- All secrets stored in Azure Key Vault
- Environment variables loaded from Key Vault
- No secrets in code or configuration files

## 🛠️ Development

### Local Development Setup

```bash
# Run the development setup script
./infrastructure/scripts/setup-dev-environment.sh
```

### Testing Infrastructure

```bash
# Test Terraform configuration
cd infrastructure/terraform
terraform validate
terraform plan

# Test Ansible playbook
cd ../ansible
ansible-playbook --check playbook.yml
```

## 📈 Scaling

### Horizontal Scaling

- Use Azure Load Balancer for multiple VMs
- Configure Redis Cluster for high availability
- Use Azure Database for PostgreSQL with read replicas

### Vertical Scaling

- Increase VM size in `terraform.tfvars`
- Adjust database tier in Terraform configuration
- Scale Redis cache tier as needed

## 🆘 Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Check security group rules
   - Verify SSH key is correct
   - Ensure VM is running

2. **Database Connection Failed**
   - Check firewall rules
   - Verify connection string
   - Check database server status

3. **Application Not Starting**
   - Check logs: `tail -f /var/log/traffic-sign-detector.log`
   - Verify environment variables
   - Check service status: `systemctl status supervisor`

### Getting Help

- Check application logs
- Review system monitoring output
- Check Azure portal for resource status
- Review GitHub Actions logs for CI/CD issues

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Azure Collection](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Django Deployment Guide](https://docs.djangoproject.com/en/stable/howto/deployment/)
