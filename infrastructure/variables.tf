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

variable "container_app_environment_name" {
  description = "The name of the Container App Environment"
  type        = string
  default     = "microservices-env"
}

variable "min_replicas" {
  description = "Minimum number of replicas for Container Apps"
  type        = number
  default     = 1

  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 10
    error_message = "Min replicas must be between 0 and 10."
  }
}

variable "max_replicas" {
  description = "Maximum number of replicas for Container Apps"
  type        = number
  default     = 3

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 20
    error_message = "Max replicas must be between 1 and 20."
  }
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

variable "container_cpu" {
  description = "CPU allocation for containers (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0)"
  type        = number
  default     = 0.5

  validation {
    condition = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.container_cpu)
    error_message = "Container CPU must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0."
  }
}

variable "container_memory" {
  description = "Memory allocation for containers (0.5Gi, 1Gi, 1.5Gi, 2Gi, 2.5Gi, 3Gi, 3.5Gi, 4Gi)"
  type        = string
  default     = "1Gi"

  validation {
    condition = contains(["0.5Gi", "1Gi", "1.5Gi", "2Gi", "2.5Gi", "3Gi", "3.5Gi", "4Gi"], var.container_memory)
    error_message = "Container memory must be one of: 0.5Gi, 1Gi, 1.5Gi, 2Gi, 2.5Gi, 3Gi, 3.5Gi, 4Gi."
  }
}

variable "enable_internal_load_balancer" {
  description = "Enable internal load balancer for Container App Environment"
  type        = bool
  default     = false
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for Container App Environment"
  type        = bool
  default     = false
}

variable "enable_mutual_tls" {
  description = "Enable mutual TLS for Container App Environment"
  type        = bool
  default     = false
}

variable "admin_email" {
  description = "Email address for receiving alerts and notifications"
  type        = string
  default     = ""
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