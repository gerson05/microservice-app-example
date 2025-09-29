terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.5"
    }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

# Variables opcionales
variable "location" {
  default = "eastus"
}

# Resource Group
resource "azurerm_resource_group" "microservices" {
  name     = "microservices-rg"
  location = var.location
}
# Obtener los outputs de la infraestructura base
data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name   = "tf-backend-rg"
    storage_account_name  = "tfbackendstorage01"
    container_name        = "tfstates"
    key                   = "infra/base.tfstate"
  }
}

locals {
  rg_name  = data.terraform_remote_state.infra.outputs.resource_group_name
  cae_id   = data.terraform_remote_state.infra.outputs.cae_id
  acr_name = data.terraform_remote_state.infra.outputs.acr_login_server
  acr_user = data.terraform_remote_state.infra.outputs.acr_admin_username
  acr_pass = data.terraform_remote_state.infra.outputs.acr_admin_password
}


# Redis
##############################
resource "azurerm_container_app" "redis" {
    name                         = "redis"
    container_app_environment_id = local.cae_id
    resource_group_name          = local.rg_name
    revision_mode                = "Single"

    template {
            min_replicas = 0
      
      container {
        name   = "redis-prueba"
        image  = "redis:7.0-alpine"
        cpu    = 0.25
        memory = "0.5Gi"
      }
    }

    ingress {
      external_enabled = false
      target_port      = 6379
      transport        = "tcp"
          traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
}

##############################
# Auth API
##############################
resource "azurerm_container_app" "auth_api" {
    name                         = "auth-api"
    container_app_environment_id = local.cae_id
    resource_group_name          = local.rg_name
    revision_mode                = "Single"

    template {
            min_replicas = 1
        max_replicas = 2 
      
      container {
        name   = "auth-api"
        image  = "${local.acr_name}/auth-api:latest"
        cpu    = 0.25
        memory = "0.5Gi"
        env {
          name  = "JWT_SECRET"
          value = "PRFT"
        }
        env {
          name  = "AUTH_API_PORT"
          value = "8000"
        }
        env {
          name  = "USERS_API_ADDRESS"
          value = "http://users-api:80"
        }
        env {
          name  = "ZIPKIN_URL"
          value = "http://zipkin:80/api/v2/spans"
        }
      }
    }

    ingress {
      external_enabled = true
      target_port      = 8000
      transport        = "http"

          traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }

    registry {
      server              = local.acr_name
      username            = local.acr_user
      password_secret_name = "acr-password"
    }

    secret {
      name  = "acr-password"
      value = local.acr_pass
    }

    depends_on = [azurerm_container_app.users_api]
  }

##############################
# Users API
##############################
  resource "azurerm_container_app" "users_api" {
    name                         = "users-api"
    container_app_environment_id = local.cae_id
    resource_group_name          = local.rg_name
    revision_mode                = "Single"

    template {
        min_replicas = 1
        max_replicas = 2 
      
      container {
        name   = "users-api"
        image  = "${local.acr_name}/users-api:latest"
        cpu    = 1.0 
        memory = "2.0Gi"
        env {
          name  = "JWT_SECRET"
          value = "PRFT"
        }
        env {
          name  = "SERVER_PORT"
          value = "8083"
        }
        env {
          name  = "ZIPKIN_URL"
          value = "http://zipkin:80"
        }
      }
    }

    ingress {
      external_enabled = true
      target_port      = 8083
      transport        = "http"

          traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }

    registry {
      server              = local.acr_name
      username            = local.acr_user
      password_secret_name = "acr-password"
    }

    secret {
      name  = "acr-password"
      value = local.acr_pass
    }

    depends_on = [
      azurerm_container_app.redis,
      azurerm_container_app.zipkin
    ]
  }

##############################
# Todos API
##############################
resource "azurerm_container_app" "todos_api" {
    name                         = "todos-api"
    container_app_environment_id = local.cae_id
    resource_group_name          = local.rg_name
    revision_mode                = "Single"

    template {
        min_replicas = 1
        max_replicas = 2 
      
      container {
        name   = "todos-api"
        image  = "${local.acr_name}/todos-api:latest"
        cpu    = 0.25
        memory = "0.5Gi"
        env {
          name  = "JWT_SECRET"
          value = "PRFT"
        }
        env {
          name  = "TODO_API_PORT"
          value = "8082"
        }
        env {
          name  = "REDIS_HOST"
          value = "redis"
        }
        env {
          name  = "REDIS_PORT"
          value = "6379"
        }
        env {
          name  = "REDIS_CHANNEL"
          value = "log_channel"
        }
        env {
          name  = "ZIPKIN_URL"
          value = "http://zipkin:80/api/v2/spans"
        }
      }
    }

    ingress {
      external_enabled = true
      target_port      = 8082
      transport        = "http"

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }

    registry {
      server               = local.acr_name
      username             = local.acr_user
      password_secret_name = "acr-password"
    }

    secret {
      name  = "acr-password"
      value = local.acr_pass
    }

    depends_on = [
      azurerm_container_app.redis,
      azurerm_container_app.auth_api
    ]
}

##############################
# Frontend
##############################
resource "azurerm_container_app" "frontend" {
    name                         = "frontend"
    container_app_environment_id = local.cae_id
    resource_group_name          = local.rg_name
    revision_mode                = "Single"

    template {
            min_replicas = 1
        max_replicas = 2 
      
      container {
        name   = "frontend"
        image  = "${local.acr_name}/frontend:latest"
        cpu    = 0.25
        memory = "0.5Gi"
        env {
          name  = "AUTH_API_URL"
          value = "auth-api:80"
        }
        env {
          name  = "TODOS_API_URL"
          value = "todos-api:80"
        }
        env {
          name  = "ZIPKIN_URL"
          value = "zipkin:80"
        }
        
      }
    }

    ingress {
      external_enabled = true
      target_port      = 80
      transport        = "http"

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }

    registry {
      server               = local.acr_name
      username             = local.acr_user
      password_secret_name = "acr-password"
    }

    secret {
      name  = "acr-password"
      value = local.acr_pass
    }

    depends_on = [
      azurerm_container_app.auth_api,
      azurerm_container_app.zipkin,
      azurerm_container_app.todos_api
    ]
}
##############################
# Zipkin
##############################
resource "azurerm_container_app" "zipkin" {
    name                         = "zipkin"
    container_app_environment_id = local.cae_id
    resource_group_name          = local.rg_name
    revision_mode                = "Single" 
    template {
            min_replicas = 0
        max_replicas = 1 
      
      container {
        name   = "zipkin"
        image  = "openzipkin/zipkin"
        cpu    = 0.25
        memory = "0.5Gi"
      }

    }
    ingress {
      external_enabled = true
      target_port      = 9411
      transport        = "http"

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
}

