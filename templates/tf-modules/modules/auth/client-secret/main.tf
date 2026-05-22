# ----------------------------
# Create a client secret (password) for the service principal
# ------------------------------
resource "azuread_service_principal_password" "mysecret" {
    count                = var.create_client_secret ? 1 : 0
    service_principal_id = var.service_principal_id
    display_name         = var.client_secret_name
    end_date_relative    = var.end_date_relative
}

# ---
# # Create a client secret for application instead
# resource "azuread_application_password" "mysecret" {
#     count          = var.create_client_secret ? 1 : 0
#     application_id  = var.application_id
#     display_name    = var.client_secret_name
#     end_date_relative = var.end_date_relative
# }
# ---

# Save SP credentials .dev.env
resource "local_file" "sp_credentials_tfvars" {
    count = (
        var.create_client_secret &&
        length(var.local_file_path) > 0
        ? 1 : 0
    )

    filename = var.local_file_path

    content  = <<EOT
# Service Principal Client Credentials for local development (do not share or commit these values)
ARM_TENANT_ID=${var.client_data.tenant_id}
ARM_SUBSCRIPTION_ID=${var.client_data.subscription_id}
ARM_CLIENT_ID=${var.client_data.client_id}
ARM_CLIENT_SECRET=${azuread_service_principal_password.mysecret[0].value}
EOT

    file_permission = "0600"
}


# # set these as TF_VAR_ variables in gh secrets instead
# TF_VAR_tenant_id=${var.client_data.tenant_id}
# TF_VAR_landing_zone_subscription_id=${var.client_data.subscription_id}
# TF_VAR_client_id=${var.client_data.client_id}
# TF_VAR_client_secret=${azuread_service_principal_password.mysecret[0].value}
# TF_VAR_principal_object_id=${var.client_data.object_id}
