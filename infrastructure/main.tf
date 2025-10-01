# Microservices Infrastructure - Main Configuration
# This file defines the main infrastructure components

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

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

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.microservices.name
  virtual_network_name = azurerm_virtual_network.microservices.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for Application Gateway
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

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "microservices" {
  name                = "microservices-aks"
  location            = azurerm_resource_group.microservices.location
  resource_group_name = azurerm_resource_group.microservices.name
  dns_prefix          = "microservices-aks"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_size
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.microservices.id
  }

  tags = {
    Environment = var.environment
    Project     = "microservices"
  }
}

# Role assignment for AKS to access ACR
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.microservices.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.microservices.kubelet_identity[0].object_id
}

# Azure Redis Cache
resource "azurerm_redis_cache" "microservices" {
  name                = "microservices-redis"
  location            = azurerm_resource_group.microservices.location
  resource_group_name = azurerm_resource_group.microservices.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
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
