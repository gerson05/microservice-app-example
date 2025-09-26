terraform {
  backend "azurerm" {
    resource_group_name   = "tf-backend-rg"
    storage_account_name  = "tfbackendstorage01"
    container_name        = "tfstates"
    key                   = "infra/base.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Grupo de recursos principal
resource "azurerm_resource_group" "core_rg" {
  name     = "rg-core-services"
  location = "East US"
}

# Registro de contenedores (ACR)
resource "azurerm_container_registry" "acr_main" {
  name                = "registrymsunique" 
  location            = azurerm_resource_group.core_rg.location
  resource_group_name = azurerm_resource_group.core_rg.name
  sku                 = "Basic"
  admin_enabled       = true
}

# Entorno para Container Apps
resource "azurerm_container_app_environment" "apps_env" {
  name                = "microapps-env"
  location            = azurerm_resource_group.core_rg.location
  resource_group_name = azurerm_resource_group.core_rg.name
}
