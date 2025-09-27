output "cae_id" {
  value = azurerm_container_app_environment.apps_env.id
}

output "acr_admin_username" {
  value = azurerm_container_registry.acr_main.admin_username
}

output "acr_admin_password" {
  value     = azurerm_container_registry.acr_main.admin_password
  sensitive = true
}

output "acr_login_server" {
  value = azurerm_container_registry.acr_main.login_server
}

output "resource_group_name" {
  value = azurerm_resource_group.core_rg.name
}

output "location" {
  value = azurerm_resource_group.core_rg.location
}
