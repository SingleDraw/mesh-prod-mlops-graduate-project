# --------------------------------
# Data source to get the current Azure client configuration (identity).
data "azurerm_client_config" "current" {}

# ---------------------------------
# State Storage Resources
# --------------------------------
# Resource group for storing Terraform state
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# --------------------------------
# Storage account and container for Terraform state
module "storage_account" {
    source                    = "{{MODULES_URL}}/storage-account{{?MODULES_TAG}}"
    name                      = var.storage_account_name
    container_name            = var.container_name
    location                  = var.location
    resource_group_name       = azurerm_resource_group.main.name

    allowed_ip_addresses      = concat(var.allowed_ip_addresses, [local.my_ip])
    disable_shared_access_key = var.disable_shared_access_key
    storage_contributors      = concat(
      var.storage_contributors, 
      [data.azurerm_client_config.current.object_id]    # current identity gets access by default
    )
    enable_https_only         = var.enable_https_only

    tags = var.tags
}


# ----------------------------
# Terraform Service Principal
# ----------------------------
module "terraform_sp" {
    source           = "{{MODULES_URL}}/auth/service-principal{{?MODULES_TAG}}"
    application_name = var.application_name
}

# ----------------------------
# Directory Role Assignment for Terraform SP
# ----------------------------
# assign Cloud Application Administrator directory role 
# to the SP (for managing app registrations and enterprise applications in Azure AD)
module "terraform_sp_directory_role" {
  source                    = "{{MODULES_URL}}/directory-role-assignement{{?MODULES_TAG}}"
  principal_object_id       = module.terraform_sp.object_id
  cloud_app_admin_role_name = "Cloud Application Administrator"
}
module "terraform_sp_directory_role_privileged" {
  source                    = "{{MODULES_URL}}/directory-role-assignement{{?MODULES_TAG}}"
  principal_object_id       = module.terraform_sp.object_id
  cloud_app_admin_role_name = "Privileged Role Administrator"
}

# ----------------------------
# RBAC for Terraform SP on TFSTATE sa *(least-privilege for managing tf state)*
# ----------------------------
# - Reader, Storage Blob Data Contributor 
#     on Storage Account (for managing tf state)
# - Role Based Access Control Administrator (for assigning RBAC on state for LZ Service Principals)
#     on tfstate resource group
module "terraform_sp_rbac_tfstate" {
  source       = "{{MODULES_URL}}/role-assignment{{?MODULES_TAG}}"
  principal_id = module.terraform_sp.object_id
  assignments  = [
    {
      scope            = module.storage_account.id
      role_definitions = [
        "Reader", 
        "User Access Administrator",
        "Storage Blob Data Contributor"
      ]
    },
  ]

  depends_on = [
    module.terraform_sp,
    module.storage_account
   ]
}

# RBAC over subscription for managing resources
module "terraform_sp_rbac_subscription" {
  source       = "{{MODULES_URL}}/role-assignment{{?MODULES_TAG}}"
  principal_id = module.terraform_sp.object_id
  assignments  = [
    {
      # Broad scope for ease of use, narrow down later.
      scope            = "/subscriptions/${var.subscription_id}"
      role_definitions = [
        "Contributor",
        "Role Based Access Control Administrator",
        "User Access Administrator",
      ]
    },
  ]

  depends_on = [
    module.terraform_sp
  ]
}

# ----------------------------
# 2.8 Client Secret for Terraform SP (for local use)
# ----------------------------
module "client_secret" {
  source               = "{{MODULES_URL}}/auth/client-secret{{?MODULES_TAG}}"
  create_client_secret = true

  service_principal_id = module.terraform_sp.service_principal_id
  end_date_relative    = var.client_secret_end_date_relative
  client_secret_name   = local.client_secret_name

  # output path for saving credentials to file (dev)
  # local_file_path      = "${path.module}/../../../secrets/.terraform-sp.secret.env"

  client_data = {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    client_id          = module.terraform_sp.client_id
    subscription_id    = var.subscription_id
  }
}

# ----------------------------
# 2.9 Federated Identity Credential for GitHub Actions OIDC (prod)
# ----------------------------
module "federated_identity" {
  # count          = var.environment == "prod" ? 1 : 0
  source         = "{{MODULES_URL}}/auth/federated-identity{{?MODULES_TAG}}"
  application_id = module.terraform_sp.application_id
  display_name   = "${var.oidc_credential_name}-platform"
  issuer         = var.oidc_issuer
  audiences      = var.oidc_audiences
  subject        = var.oidc_subject
  depends_on     = [module.terraform_sp]
}

module "federated_identity_azureml" {
  # count          = var.environment == "prod" ? 1 : 0
  source         = "{{MODULES_URL}}/auth/federated-identity{{?MODULES_TAG}}"
  application_id = module.terraform_sp.application_id
  display_name   = "${var.oidc_credential_name}-azureml"
  issuer         = var.oidc_issuer
  audiences      = var.oidc_audiences
  subject        = var.oidc_subject_azureml
  depends_on     = [module.terraform_sp]
}

module "federated_identity_databricks" {
  # count          = var.environment == "prod" ? 1 : 0
  source         = "{{MODULES_URL}}/auth/federated-identity{{?MODULES_TAG}}"
  application_id = module.terraform_sp.application_id
  display_name   = "${var.oidc_credential_name}-databricks"
  issuer         = var.oidc_issuer
  audiences      = var.oidc_audiences
  subject        = var.oidc_subject_databricks
  depends_on     = [module.terraform_sp]
}