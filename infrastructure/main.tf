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

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
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
  name                = "microservices-redis"
  location            = azurerm_resource_group.microservices.location
  resource_group_name = azurerm_resource_group.microservices.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  non_ssl_port_enabled = false
  minimum_tls_version = "1.2"

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Azure Database for PostgreSQL (if needed)
resource "azurerm_postgresql_flexible_server" "microservices" {
  count               = var.enable_database ? 1 : 0
  name                = "microservices-postgres"
  resource_group_name = azurerm_resource_group.microservices.name
  location            = azurerm_resource_group.microservices.location
  version             = "13"
  administrator_login = var.db_admin_username
  administrator_password = var.db_admin_password
  zone                = "1"
  storage_mb          = 32768
  sku_name            = "GP_Standard_D2s_v3"

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
  log_analytics_workspace_id = azurerm_log_analytics_workspace.microservices.id

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Frontend Container App
resource "azurerm_container_app" "frontend" {
  name                         = "frontend"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "alejomunoz/frontend:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "NODE_ENV"
        value = var.environment
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "frontend"
  }
}

# Auth API Container App
resource "azurerm_container_app" "auth_api" {
  name                         = "auth-api"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    min_replicas = var.min_replicas
    container {
      name   = "auth-api"
      image  = "alejomunoz/auth-api:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "8081"
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "auth-api"
  }
}

# Todos API Container App
resource "azurerm_container_app" "todos_api" {
  name                         = "todos-api"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    container {
      name   = "todos-api"
      image  = "alejomunoz/todos-api:latest"
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
  }


  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "todos-api"
  }
}

# Users API Container App
resource "azurerm_container_app" "users_api" {
  name                         = "users-api"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    container {
      name   = "users-api"
      image  = "alejomunoz/users-api:latest"
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
  }


  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "users-api"
  }
}

# Log Processor Container App (no HTTP, solo internal)
resource "azurerm_container_app" "log_processor" {
  name                         = "log-processor"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    container {
      name   = "log-processor"
      image  = "alejomunoz/log-processor:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "log-processor"
  }
}

resource "azurerm_container_app" "zipkin" {
  name                         = "zipkin"
  container_app_environment_id = azurerm_container_app_environment.microservices_env.id
  resource_group_name          = azurerm_resource_group.microservices.name
  revision_mode                = "Single"

  template {
    container {
      name   = "zipkin"
      image  = "openzipkin/zipkin:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "STORAGE_TYPE"
        value = "mem"
      }
    }

  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
    Service     = "zipkin"
  }
}
