# Microservices Infrastructure - Main Configuration
# This file defines the main infrastructure components for Azure Container Apps

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Data sources
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "microservices" {
  name     = "microservices-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "microservices"
    ManagedBy   = "terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "microservices" {
  name                = "microservices-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.microservices.location
  resource_group_name = azurerm_resource_group.microservices.name

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Subnet for Container Apps Environment
resource "azurerm_subnet" "container_apps" {
  name                 = "container-apps-subnet"
  resource_group_name  = azurerm_resource_group.microservices.name
  virtual_network_name = azurerm_virtual_network.microservices.name
  address_prefixes     = ["10.0.0.0/23"]
  
  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Subnet for Application Gateway (optional)
resource "azurerm_subnet" "appgw" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.microservices.name
  virtual_network_name = azurerm_virtual_network.microservices.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Azure Container Registry
resource "azurerm_container_registry" "microservices" {
  name                = "microservicesacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.microservices.name
  location            = azurerm_resource_group.microservices.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "microservices" {
  name                = "microservices-logs"
  location            = azurerm_resource_group.microservices.location
  resource_group_name = azurerm_resource_group.microservices.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Application Insights
resource "azurerm_application_insights" "microservices" {
  name                = "microservices-insights"
  location            = azurerm_resource_group.microservices.location
  resource_group_name = azurerm_resource_group.microservices.name
  workspace_id        = azurerm_log_analytics_workspace.microservices.id
  application_type    = "web"

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}


# Azure Redis Cache
resource "azurerm_redis_cache" "microservices" {
  name                 = "microservices-redis"
  location             = azurerm_resource_group.microservices.location
  resource_group_name  = azurerm_resource_group.microservices.name
  capacity             = 1
  family               = "C"
  sku_name             = "Standard"
  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Azure Database for PostgreSQL (if needed)
resource "azurerm_postgresql_flexible_server" "microservices" {
  count                  = var.enable_database ? 1 : 0
  name                   = "microservices-postgres"
  resource_group_name    = azurerm_resource_group.microservices.name
  location               = azurerm_resource_group.microservices.location
  version                = "13"
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Key Vault for secrets
resource "azurerm_key_vault" "microservices" {
  name                = "microservices-kv${random_string.suffix.result}"
  location            = azurerm_resource_group.microservices.location
  resource_group_name = azurerm_resource_group.microservices.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update",
      "Import",
      "Backup",
      "Restore",
      "Recover"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Backup",
      "Restore",
      "Recover"
    ]
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.microservices.id
}

resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = azurerm_redis_cache.microservices.primary_access_key
  key_vault_id = azurerm_key_vault.microservices.id
}
# Azure Container App Environment
resource "azurerm_container_app_environment" "microservices_env" {
  name                       = "microservices-env"
  location                   = azurerm_resource_group.microservices.location
  resource_group_name        = azurerm_resource_group.microservices.name
  # infrastructure_subnet_id   = azurerm_subnet.container_apps.id  # Comentado temporalmente
  # internal_load_balancer_enabled = var.environment == "prod" ? true : false  # Requiere subnet
  # zone_redundancy_enabled    = var.environment == "prod" ? true : false  # Requiere subnet
  # mutual_tls_enabled         = var.environment == "prod" ? true : false  # Requiere subnet

  log_analytics_workspace_id = azurerm_log_analytics_workspace.microservices.id

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Frontend Container App
resource "azurerm_container_app" "frontend" {
  name                         = "frontend-app"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "nginx:alpine"  
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "NODE_ENV"
        value = var.environment
      }
    }

    min_replicas = 1
    max_replicas = var.environment == "prod" ? 5 : 2
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "frontend"
  }
}

# Auth API Container App
resource "azurerm_container_app" "auth_api" {
  name                         = "auth-api-app"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  secret {
    name  = "jwt-secret"
    value = var.jwt_secret
  }

  secret {
    name  = "redis-password"
    value = azurerm_redis_cache.microservices.primary_access_key
  }

  template {
    container {
      name   = "auth-api"
      image  = "httpd:alpine"  # Imagen temporal para testing
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.microservices.hostname
      }

      env {
        name        = "REDIS_PASSWORD"
        secret_name = "redis-password"
      }

      env {
        name        = "JWT_SECRET"
        secret_name = "jwt-secret"
      }

      env {
        name  = "PORT"
        value = "8080"
      }
    }

    min_replicas = 1
    max_replicas = var.environment == "prod" ? 3 : 2
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "auth-api"
  }
}

# Todos API Container App
resource "azurerm_container_app" "todos_api" {
  name                         = "todos-api-app"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    container {
      name   = "todos-api"
      image  = "httpd:alpine"  # Imagen temporal para testing
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }

      env {
        name  = "NODE_ENV"
        value = var.environment
      }
    }

    min_replicas = 1
    max_replicas = var.environment == "prod" ? 3 : 2
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "todos-api"
  }
}

# Users API Container App
resource "azurerm_container_app" "users_api" {
  name                         = "users-api-app"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    container {
      name   = "users-api"
      image  = "httpd:alpine" 
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "8080"
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = var.environment
      }
    }

    min_replicas = 1
    max_replicas = var.environment == "prod" ? 3 : 2
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "users-api"
  }
}