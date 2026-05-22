output "client_id" {
    value = azuread_application.myapp.client_id
    description = "The application (client) ID of the created service principal. Used for authentication."
}

output "object_id" {
    value = azuread_service_principal.mysp.object_id
    description = "The object ID of the created service principal in Azure AD. Used for role assignments and permissions."
}

output "service_principal_id" {
    value = azuread_service_principal.mysp.id
    description = "The principal ID of the created service principal. This is the same as the object ID and can be used interchangeably for role assignments."
}

output "application_id" {
  value = azuread_application.myapp.id  # "/applications/91449501-..."
}