# Microservices Infrastructure - Outputs
# This file defines the outputs of the infrastructure

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.microservices.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.microservices.location
}

output "kubernetes_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.microservices.name
}

output "kubernetes_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.microservices.id
}

output "kubernetes_cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.microservices.fqdn
}

output "kubernetes_cluster_private_fqdn" {
  description = "The private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.microservices.private_fqdn
}

output "kubernetes_cluster_portal_fqdn" {
  description = "The portal FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.microservices.portal_fqdn
}

output "kubernetes_cluster_kube_config" {
  description = "The kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.microservices.kube_config_raw
  sensitive   = true
}

output "container_registry_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.microservices.name
}

output "container_registry_login_server" {
  description = "The login server of the Azure Container Registry"
  value       = azurerm_container_registry.microservices.login_server
}

output "container_registry_admin_username" {
  description = "The admin username of the Azure Container Registry"
  value       = azurerm_container_registry.microservices.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "The admin password of the Azure Container Registry"
  value       = azurerm_container_registry.microservices.admin_password
  sensitive   = true
}

output "redis_cache_name" {
  description = "The name of the Redis cache"
  value       = azurerm_redis_cache.microservices.name
}

output "redis_cache_hostname" {
  description = "The hostname of the Redis cache"
  value       = azurerm_redis_cache.microservices.hostname
}

output "redis_cache_port" {
  description = "The port of the Redis cache"
  value       = azurerm_redis_cache.microservices.port
}

output "redis_cache_primary_key" {
  description = "The primary key of the Redis cache"
  value       = azurerm_redis_cache.microservices.primary_access_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.microservices.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.microservices.name
}

output "application_insights_id" {
  description = "The ID of the Application Insights"
  value       = azurerm_application_insights.microservices.id
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key of Application Insights"
  value       = azurerm_application_insights.microservices.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string of Application Insights"
  value       = azurerm_application_insights.microservices.connection_string
  sensitive   = true
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.microservices.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.microservices.vault_uri
}

output "postgresql_server_name" {
  description = "The name of the PostgreSQL server (if enabled)"
  value       = var.enable_database ? azurerm_postgresql_flexible_server.microservices[0].name : null
}

output "postgresql_server_fqdn" {
  description = "The FQDN of the PostgreSQL server (if enabled)"
  value       = var.enable_database ? azurerm_postgresql_flexible_server.microservices[0].fqdn : null
}

output "postgresql_server_port" {
  description = "The port of the PostgreSQL server (if enabled)"
  value       = var.enable_database ? azurerm_postgresql_flexible_server.microservices[0].port : null
}

# Connection strings and configuration
output "connection_strings" {
  description = "Connection strings for all services"
  value = {
    redis = "redis://:${azurerm_redis_cache.microservices.primary_access_key}@${azurerm_redis_cache.microservices.hostname}:${azurerm_redis_cache.microservices.port}"
    postgresql = var.enable_database ? "postgresql://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.microservices[0].fqdn}:${azurerm_postgresql_flexible_server.microservices[0].port}/postgres" : null
  }
  sensitive = true
}

# Deployment information
output "deployment_info" {
  description = "Information about the deployment"
  value = {
    environment = var.environment
    location    = azurerm_resource_group.microservices.location
    created_at  = timestamp()
    version     = "1.0.0"
  }
}
