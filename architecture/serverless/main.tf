# Serverless Architecture - Azure Functions + Static Web Apps + Managed Services
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
  
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Architecture = "serverless"
  }
}

# Random suffix
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Storage Account for Function App
resource "azurerm_storage_account" "function" {
  name                     = "${var.project_name}${random_string.suffix.result}func"
  resource_group_name      = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# App Service Plan (Consumption for serverless)
resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  os_type            = "Linux"
  sku_name           = "Y1"  # Consumption plan

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Function App for Backend API
resource "azurerm_linux_function_app" "backend" {
  name                = "${var.project_name}-backend-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  service_plan_id    = azurerm_service_plan.main.id

  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  site_config {
    application_stack {
      python_version = "3.10"
    }
    
    cors {
      allowed_origins = [
        "https://${azurerm_static_web_app.frontend.default_host_name}",
        "http://localhost:3000"
      ]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "AzureWebJobsStorage" = azurerm_storage_account.function.primary_connection_string
    "DATABASE_URL" = "postgresql://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_name}?sslmode=require"
    "REDIS_URL" = "rediss://:${var.redis_password}@${azurerm_redis_cache.main.hostname}:6380/0"
    "SECRET_KEY" = var.django_secret_key
    "DEBUG" = "False"
    "ALLOWED_HOSTS" = "*.azurewebsites.net"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Static Web App for Frontend
resource "azurerm_static_web_app" "frontend" {
  name                = "${var.project_name}-frontend-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location           = "West Europe 2"  # Static Web Apps have limited regions
  sku_tier           = "Free"
  sku_size           = "Free"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-${random_string.suffix.result}-psql"
  resource_group_name    = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  version               = "13"
  administrator_login   = var.db_admin_username
  administrator_password = var.db_admin_password
  zone                  = "1"
  backup_retention_days = 7
  geo_redundant_backup_enabled = false

  storage_mb = 32768
  sku_name   = "GP_Standard_D2s_v3"

  high_availability {
    mode = "ZoneRedundant"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL Firewall Rule
resource "azurerm_postgresql_flexible_server_firewall_rule" "main" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = "${var.project_name}-${random_string.suffix.result}-redis"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-${random_string.suffix.result}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled = true
  soft_delete_retention_days = 7

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Get current client config
data "azurerm_client_config" "current" {}

# Key Vault Access Policy for Function App
resource "azurerm_key_vault_access_policy" "function_app" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = azurerm_linux_function_app.backend.identity[0].tenant_id
  object_id    = azurerm_linux_function_app.backend.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Key Vault Access Policy for current user
resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.main]
}

resource "azurerm_key_vault_secret" "django_secret" {
  name         = "django-secret-key"
  value        = var.django_secret_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.main]
}

# API Management (optional - for advanced API management)
resource "azurerm_api_management" "main" {
  count               = var.enable_api_management ? 1 : 0
  name                = "${var.project_name}-apim-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = var.api_publisher_name
  publisher_email     = var.api_publisher_email

  sku_name = "Developer_1"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Event Grid for real-time notifications
resource "azurerm_eventgrid_topic" "main" {
  name                = "${var.project_name}-events"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Logic App for workflow automation
resource "azurerm_logic_app_workflow" "main" {
  name                = "${var.project_name}-workflow"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Azure Cognitive Services for AI features
resource "azurerm_cognitive_account" "computer_vision" {
  name                = "${var.project_name}-cv-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "ComputerVision"
  sku_name           = "S1"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
