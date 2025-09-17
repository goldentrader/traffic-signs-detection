# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "traffic-sign-detector"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# Database Configuration
variable "db_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "trafficadmin"
}

variable "db_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "traffic_sign_db"
}

# Django Configuration
variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  default     = ""
  sensitive   = true
}

# Redis Configuration
variable "redis_password" {
  description = "Redis password"
  type        = string
  default     = ""
  sensitive   = true
}

# Application Configuration
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "Traffic Sign Detector"
}

variable "app_env" {
  description = "Application environment"
  type        = string
  default     = "production"
}

# Container Registry
variable "container_registry_sku" {
  description = "Container Registry SKU"
  type        = string
  default     = "Basic"
}

# PostgreSQL Configuration
variable "postgresql_sku" {
  description = "PostgreSQL SKU"
  type        = string
  default     = "B_Gen5_1"
}

# Redis Configuration
variable "redis_sku" {
  description = "Redis SKU"
  type        = string
  default     = "Basic"
}

# Container Apps Configuration
variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}

variable "cpu_limit" {
  description = "CPU limit for containers"
  type        = string
  default     = "1.0"
}

variable "memory_limit" {
  description = "Memory limit for containers"
  type        = string
  default     = "2Gi"
}

# Domain Configuration
variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = ""
}

variable "dns_zone_id" {
  description = "DNS zone ID"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "traffic-sign-detector"
    Owner       = "ossama.elouadih-etu@etu.univh2c.ma"
    CostCenter  = "development"
  }
}
