# ----------------------------
# Create federated credentials with GitHub Actions OIDC 
# (no client secret)
# ----------------------------
# in gh secrets, set:
# AZURE_CLIENT_ID = azuread_application.github_actions.client_id
# AZURE_TENANT_ID = var.tenant_id
# ----------------------------

resource "azuread_application_federated_identity_credential" "this" {
    application_id       = var.application_id
    display_name         = var.display_name
    issuer               = var.issuer
    subject              = var.subject
    audiences            = var.audiences
}