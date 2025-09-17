# Fully Containerized Architecture - Azure Container Apps + Managed Services
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data sources
data "azurerm_client_config" "current" {}

# Random password generator
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "random_password" "redis_password" {
  length  = 16
  special = true
}

resource "random_password" "django_secret" {
  length  = 50
  special = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv-traffic-sign-prod"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }

  tags = var.tags
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_admin_password != "" ? var.db_admin_password : random_password.db_password.result
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = var.redis_password != "" ? var.redis_password : random_password.redis_password.result
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "django_secret" {
  name         = "django-secret"
  value        = var.django_secret_key != "" ? var.django_secret_key : random_password.django_secret.result
  key_vault_id = azurerm_key_vault.main.id
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acrtrafficsignprod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.container_registry_sku
  admin_enabled       = true
  tags                = var.tags
}

# PostgreSQL Database - using centralus for better availability
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-traffic-sign-prod-new"
  resource_group_name    = azurerm_resource_group.main.name
  location               = "centralus"  # Using centralus to avoid location restrictions
  version                = "13"
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password != "" ? var.db_admin_password : random_password.db_password.result
  zone                   = "1"

  storage_mb = 32768
  sku_name   = "B_Standard_B1ms"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 0
  family              = "C"
  sku_name            = var.redis_sku
  non_ssl_port_enabled = false
  minimum_tls_version = "1.2"

  redis_configuration {
    maxmemory_policy = "allkeys-lru"
  }

  tags = var.tags
}

# Storage Account for static files
resource "azurerm_storage_account" "main" {
  name                     = "sttrafficsignprod"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }

  tags = var.tags
}

# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project_name}-${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = var.tags
}

# Backend Container App
resource "azurerm_container_app" "backend" {
  name                         = "backend-traffic-prod"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "backend"
      image  = "${azurerm_container_registry.main.login_server}/traffic-sign-backend:latest"
      cpu    = var.cpu_limit
      memory = var.memory_limit

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_admin_username}:${var.db_admin_password != "" ? var.db_admin_password : random_password.db_password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_name}"
      }

      env {
        name  = "REDIS_URL"
        value = "redis://:${var.redis_password != "" ? var.redis_password : random_password.redis_password.result}@${azurerm_redis_cache.main.hostname}:6380/0"
      }

      env {
        name  = "SECRET_KEY"
        value = var.django_secret_key != "" ? var.django_secret_key : random_password.django_secret.result
      }

      env {
        name  = "DEBUG"
        value = "False"
      }

      env {
        name  = "ALLOWED_HOSTS"
        value = "*"
      }
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port               = 8000
    transport                 = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

# Frontend Container App
resource "azurerm_container_app" "frontend" {
  name                         = "frontend-traffic-prod"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.main.login_server}/traffic-sign-frontend:latest"
      cpu    = "0.5"
      memory = "1Gi"

      env {
        name  = "REACT_APP_API_URL"
        value = "https://${azurerm_container_app.backend.latest_revision_fqdn}"
      }
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port               = 3000
    transport                 = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}
