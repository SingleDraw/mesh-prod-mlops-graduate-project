output "client_secret" {
    value = azuread_service_principal_password.mysecret[0].value
    sensitive = true
    description = "The client secret value for the service principal. Keep this secure and do not share it publicly."
}

# ---
# # output for application secret instead
# output "client_secret" {
#     value = azuread_application_password.mysecret[0].value
#     sensitive = true
#     description = "The client secret value for the application. Keep this secure and do not share it publicly."
# }
# ---
