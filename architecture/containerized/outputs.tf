# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Container Registry
output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Container Registry admin username"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Container Registry admin password"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# PostgreSQL Database
output "postgresql_server_name" {
  description = "PostgreSQL server name"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_server_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_database_name" {
  description = "PostgreSQL database name"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

# Redis Cache
output "redis_cache_name" {
  description = "Redis cache name"
  value       = azurerm_redis_cache.main.name
}

output "redis_cache_hostname" {
  description = "Redis cache hostname"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_cache_port" {
  description = "Redis cache port"
  value       = azurerm_redis_cache.main.port
}

# Container Apps
output "container_app_environment_name" {
  description = "Container App Environment name"
  value       = azurerm_container_app_environment.main.name
}

output "backend_app_name" {
  description = "Backend Container App name"
  value       = azurerm_container_app.backend.name
}

output "backend_app_fqdn" {
  description = "Backend Container App FQDN"
  value       = azurerm_container_app.backend.latest_revision_fqdn
}

output "frontend_app_name" {
  description = "Frontend Container App name"
  value       = azurerm_container_app.frontend.name
}

output "frontend_app_fqdn" {
  description = "Frontend Container App FQDN"
  value       = azurerm_container_app.frontend.latest_revision_fqdn
}

# Key Vault
output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

# Application Insights
output "application_insights_name" {
  description = "Application Insights name"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# Storage Account
output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_web_endpoint" {
  description = "Storage account primary web endpoint"
  value       = azurerm_storage_account.main.primary_web_endpoint
}

# Log Analytics
output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}
