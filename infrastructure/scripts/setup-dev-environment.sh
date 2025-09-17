#!/bin/bash

# Traffic Sign Detection System - Development Environment Setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running on Ubuntu/Debian
if ! command -v apt-get >/dev/null 2>&1; then
    log_error "This script is designed for Ubuntu/Debian systems"
    exit 1
fi

log_info "Setting up development environment for Traffic Sign Detection System..."

# Update system packages
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python 3.10
log_info "Installing Python 3.10..."
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.10 python3.10-venv python3.10-dev python3-pip

# Install Node.js 20
log_info "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install system dependencies
log_info "Installing system dependencies..."
sudo apt install -y \
    build-essential \
    libpq-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    wget \
    curl \
    git \
    nginx \
    supervisor \
    redis-server \
    postgresql-client \
    docker.io \
    docker-compose

# Install development tools
log_info "Installing development tools..."
sudo apt install -y \
    vim \
    htop \
    tree \
    jq \
    unzip

# Install Azure CLI
log_info "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform
log_info "Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# Install Ansible
log_info "Installing Ansible..."
sudo apt install -y ansible

# Install Docker Compose
log_info "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
log_info "Adding user to docker group..."
sudo usermod -aG docker $USER

# Start and enable services
log_info "Starting and enabling services..."
sudo systemctl start redis-server
sudo systemctl enable redis-server
sudo systemctl start docker
sudo systemctl enable docker

# Install Python development dependencies
log_info "Installing Python development dependencies..."
pip3 install --user \
    virtualenv \
    pipenv \
    black \
    flake8 \
    isort \
    pytest \
    pytest-django \
    pytest-cov

# Install Node.js development dependencies
log_info "Installing Node.js development dependencies..."
npm install -g \
    eslint \
    prettier \
    nodemon \
    pm2

# Create project directories
log_info "Creating project directories..."
mkdir -p ~/projects
mkdir -p ~/.ssh

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    log_info "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_rsa -N ""
    log_success "SSH key generated at ~/.ssh/id_rsa"
    log_info "Add the following public key to your GitHub account:"
    cat ~/.ssh/id_rsa.pub
fi

# Create environment file template
log_info "Creating environment file template..."
cat > .env.example << ENV_EOF
# Traffic Sign Detection System - Environment Variables

# Django Settings
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/traffic_sign_detector
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Email Configuration (optional)
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=noreply@trafficsigndetector.com

# Azure Configuration (for production)
AZURE_STORAGE_ACCOUNT_NAME=
AZURE_STORAGE_ACCOUNT_KEY=
AZURE_CONTAINER_NAME=media

# Application Insights (for production)
APPLICATIONINSIGHTS_CONNECTION_STRING=

# CORS Settings
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Model Configuration
MODEL_PATH=./yolov8-gtsrb-trained.pt
ENV_EOF

log_success "Development environment setup completed!"
log_info "Please restart your terminal or run 'source ~/.bashrc' to apply changes"
log_info "Don't forget to:"
log_info "1. Copy .env.example to .env and configure it"
log_info "2. Add your SSH public key to GitHub"
log_info "3. Configure Azure CLI with 'az login'"
log_info "4. Set up your database and Redis services"
