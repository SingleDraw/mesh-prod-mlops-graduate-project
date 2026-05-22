# 1. Register an Azure AD application
resource "azuread_application" "myapp" {
    display_name = var.application_name
}

# 2. Create a service principal for that application
# the same application can have multiple SPs from different tenants, 
# or even the same tenant for different purposes
resource "azuread_service_principal" "mysp" {
    client_id = azuread_application.myapp.client_id
    depends_on = [azuread_application.myapp]
}

# enforce waiting for the SP to be fully created before proceeding
data "azuread_service_principal" "mysp" {
    object_id = azuread_service_principal.mysp.object_id
    depends_on = [azuread_service_principal.mysp]
}

# Use this sp id to assign roles to the SP, for example:

# resource "azurerm_role_assignment" "sp_storage" {
#   scope                = azurerm_storage_account.this.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azuread_service_principal.mysp.id
# }
# # This allows your SP to access Blob Storage without shared keys.
