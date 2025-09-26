terraform {
  backend "azurerm" {
    resource_group_name   = "tf-rg-backend"
    storage_account_name  = "tfstateaccountdev"
    container_name        = "tfstatefiles"
    key                   = "apps/services.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 🔗 Referencia al estado remoto de la infraestructura base
data "terraform_remote_state" "base_infra" {
  backend = "azurerm"
  config = {
    resource_group_name   = "tf-rg-backend"
    storage_account_name  = "tfstateaccountdev"
    container_name        = "tfstatefiles"
    key                   = "infra/core.tfstate"
  }
}

# Variables locales con alias diferentes
locals {
  rg_ms         = data.terraform_remote_state.base_infra.outputs.resource_group_name
  env_container = data.terraform_remote_state.base_infra.outputs.cae_id
  registry_srv  = data.terraform_remote_state.base_infra.outputs.acr_login_server
  registry_usr  = data.terraform_remote_state.base_infra.outputs.acr_admin_username
  registry_pwd  = data.terraform_remote_state.base_infra.outputs.acr_admin_password
}

# =======================
# Users API
# =======================
resource "azurerm_container_app" "svc_users" {
  name                         = "svc-users"
  container_app_environment_id = local.env_container
  resource_group_name          = local.rg_ms
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "users-api"
      image  = "${local.registry_srv}/users-api:latest"
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
    server               = local.registry_srv
    username             = local.registry_usr
    password_secret_name = "acr-secret"
  }

  secret {
    name  = "acr-secret"
    value = local.registry_pwd
  }
}

# =======================
# Auth API
# =======================
resource "azurerm_container_app" "svc_auth" {
  name                         = "svc-auth"
  container_app_environment_id = local.env_container
  resource_group_name          = local.rg_ms
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "auth-api"
      image  = "${local.registry_srv}/auth-api:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "JWT_SECRET"
        value = "PRFT"
      }
      env {
        name  = "AUTH_API_PORT"
        value = "8081"
      }
      env {
        name  = "USERS_API_ADDRESS"
        value = "http://svc-users:80"
      }
      env {
        name  = "ZIPKIN_URL"
        value = "http://zipkin:80/api/v2/spans"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8081
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = local.registry_srv
    username             = local.registry_usr
    password_secret_name = "acr-secret"
  }

  secret {
    name  = "acr-secret"
    value = local.registry_pwd
  }

  depends_on = [azurerm_container_app.svc_users]
}

# =======================
# Todos API
# =======================
resource "azurerm_container_app" "svc_todos" {
  name                         = "svc-todos"
  container_app_environment_id = local.env_container
  resource_group_name          = local.rg_ms
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "todos-api"
      image  = "${local.registry_srv}/todos-api:latest"
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
        value = "svc-redis"
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
    server               = local.registry_srv
    username             = local.registry_usr
    password_secret_name = "acr-secret"
  }

  secret {
    name  = "acr-secret"
    value = local.registry_pwd
  }

  depends_on = [
    azurerm_container_app.svc_redis,
    azurerm_container_app.svc_auth
  ]
}

# =======================
# Log Processor
# =======================
resource "azurerm_container_app" "svc_logproc" {
  name                         = "svc-logproc"
  container_app_environment_id = local.env_container
  resource_group_name          = local.rg_ms
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "log-processor"
      image  = "${local.registry_srv}/log-message-processor:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "REDIS_HOST"
        value = "svc-redis"
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

  registry {
    server               = local.registry_srv
    username             = local.registry_usr
    password_secret_name = "acr-secret"
  }

  secret {
    name  = "acr-secret"
    value = local.registry_pwd
  }

  depends_on = [
    azurerm_container_app.svc_redis,
    azurerm_container_app.svc_zipkin
  ]
}

# =======================
# Frontend
# =======================
resource "azurerm_container_app" "svc_frontend" {
  name                         = "svc-frontend"
  container_app_environment_id = local.env_container
  resource_group_name          = local.rg_ms
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "frontend"
      image  = "${local.registry_srv}/frontend:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "AUTH_API_URL"
        value = "svc-auth:80"
      }
      env {
        name  = "TODOS_API_URL"
        value = "svc-todos:80"
      }
      env {
        name  = "USERS_API_URL"
        value = "svc-users:80"
      }
      env {
        name  = "ZIPKIN_URL"
        value = "svc-zipkin:80"
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
    server               = local.registry_srv
    username             = local.registry_usr
    password_secret_name = "acr-secret"
  }

  secret {
    name  = "acr-secret"
    value = local.registry_pwd
  }

  depends_on = [
    azurerm_container_app.svc_auth,
    azurerm_container_app.svc_todos,
    azurerm_container_app.svc_users,
    azurerm_container_app.svc_zipkin
  ]
}

# =======================
# Redis
# =======================
resource "azurerm_container_app" "svc_redis" {
  name                         = "svc-redis"
  container_app_environment_id = local.env_container
  resource_group_name          = local.rg_ms
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "redis"
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

# =======================
# Zipkin
# =======================
resource "azurerm_container_app" "svc_zipkin" {
  name                         = "svc-zipkin"
  container_app_environment_id = local.env_container
  resource_group_name          = local.rg_ms
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 2

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
