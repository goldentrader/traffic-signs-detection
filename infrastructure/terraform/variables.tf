# Traffic Sign Detection System - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "traffic-sign-detector"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true
}

variable "db_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "postgres"
}

variable "db_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "traffic_sign_detector"
}

variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "ssl_certificate_path" {
  description = "Path to SSL certificate"
  type        = string
  default     = ""
}

variable "ssl_private_key_path" {
  description = "Path to SSL private key"
  type        = string
  default     = ""
}
