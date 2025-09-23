# Microservices Infrastructure - Variables
# This file defines all the variables used in the infrastructure

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "The environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use for AKS"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "The number of nodes in the AKS cluster"
  type        = number
  default     = 2
  
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "node_size" {
  description = "The size of the AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_database" {
  description = "Whether to create a PostgreSQL database"
  type        = bool
  default     = false
}

variable "db_admin_username" {
  description = "The admin username for the PostgreSQL database"
  type        = string
  default     = "microservices_admin"
  sensitive   = true
}

variable "db_admin_password" {
  description = "The admin password for the PostgreSQL database"
  type        = string
  default     = "Microservices123!"
  sensitive   = true
}

variable "jwt_secret" {
  description = "The JWT secret for authentication"
  type        = string
  default     = "your-super-secret-jwt-key-change-this-in-production"
  sensitive   = true
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default = {
    Project     = "microservices"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}

variable "monitoring_enabled" {
  description = "Whether to enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Whether to enable backup for the infrastructure"
  type        = bool
  default     = false
}

variable "security_center_enabled" {
  description = "Whether to enable Azure Security Center"
  type        = bool
  default     = true
}

variable "network_security_group_rules" {
  description = "Custom network security group rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = [
    {
      name                       = "AllowHTTPS"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTP"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}
