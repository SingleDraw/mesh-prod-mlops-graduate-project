# pass this login_server URL to github sercret as ACR_LOGIN_SERVER for use in CI/CD workflows
output "login_server" {
    value       = azurerm_container_registry.this.login_server
    description = "Login server URL for the Azure Container Registry (ACR)."
}

# # Admin credentials are not needed when using OIDC or managed identities, so we do not output them here. If needed for other use cases, they can be enabled and outputted as shown below (not recommended for CI/CD scenarios due to security best practices).
# output "admin_username" {
#     value       = azurerm_container_registry.this.admin_username
#     description = "Admin username for the Azure Container Registry (ACR)."
# }

# output "admin_password" {
#     value       = azurerm_container_registry.this.admin_password
#     description = "Admin password for the Azure Container Registry (ACR)."
#     sensitive   = true
# }