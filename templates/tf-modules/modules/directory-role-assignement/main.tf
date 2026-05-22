data "azuread_directory_role_templates" "all" {}

# assign Cloud Application Administrator directory role to the SP (for managing app registrations and enterprise applications in Azure AD)
resource "azuread_directory_role_assignment" "platform_sp_application_admin" {
    role_id                 = local.cloud_app_admin_role_id
    principal_object_id     = var.principal_object_id
}
