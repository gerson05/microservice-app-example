output "cae_id" {
  description = "ID del entorno de Container Apps."
  value       = azurerm_container_app_environment.cae.id
}

output "acr_admin_password" {
  description = "Contraseña del ACR."
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "resource_group_name" {
  description = "El nombre del grupo de recursos."
  value       = azurerm_resource_group.rg.name
}
output "acr_login_server" {
  description = "El servidor de login del ACR."
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Admin del ACR."
  value       = azurerm_container_registry.acr.admin_username
}

output "location" {
  description = "La ubicación del grupo de recursos."
  value       = azurerm_resource_group.rg.location
}
