terraform {
    required_providers {
        azuread = {
            source  = "hashicorp/azuread"
            version = "~> 2.47"
        }

        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.0"
        }
    }
}

data "azurerm_client_config" "current" {}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}

provider "azuread" {}


# == RG ===========================================
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# == Storage Account (ADLS Gen2) ==================
resource "azurerm_storage_account" "datalake" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  is_hns_enabled = true  # CRITICAL (ADLS Gen2)

  # disable soft delete
  blob_properties {
    delete_retention_policy {
      permanent_delete_enabled = true
    }
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
}

# == Storage Container =============================
resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"

  depends_on = [
    azurerm_storage_account.datalake
  ]
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"

  depends_on = [
    azurerm_storage_account.datalake
  ]
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"

  depends_on = [
    azurerm_storage_account.datalake
  ]
}


# ==================================================
# UAMI for storage access
# ==================================================
resource "azurerm_user_assigned_identity" "sa_uami" { # DOESNT WORK WITH DATABRICKS
  name                = var.sa_uami_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  depends_on = [
    azurerm_resource_group.rg
  ]
}

# == RBAC (Reader) for Storage Access ==============
resource "azurerm_role_assignment" "sa_uami_storage_blob_data_reader" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.sa_uami.principal_id

  depends_on = [
    azurerm_user_assigned_identity.sa_uami,
    azurerm_storage_account.datalake
  ]
}

# == RBAC (Contributor) for Storage Access =========
resource "azurerm_role_assignment" "sa_uami_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.sa_uami.principal_id

  depends_on = [
    azurerm_user_assigned_identity.sa_uami,
    azurerm_storage_account.datalake,
  ]
}

# for current sp to upload MLTable - its used in AzureML repo for CI/CD
resource "azurerm_role_assignment" "sp_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id # current user gets contributor access by default

  depends_on = [
    data.azurerm_client_config.current,
    azurerm_storage_account.datalake,
  ]
}

# ==================================================
# Service Principal for Databricks
# ==================================================
resource "azuread_application" "databricks_sp" {
  display_name               = "${var.resource_group_name}-databricks-sp"
}

resource "azuread_service_principal" "databricks_sp" {
  client_id     = azuread_application.databricks_sp.client_id
  depends_on    = [azuread_application.databricks_sp]
}

# wait until SP is fully provisioned before creating credentials
data "azuread_service_principal" "databricks_sp" {
  object_id = azuread_service_principal.databricks_sp.object_id
  depends_on = [azuread_service_principal.databricks_sp]
}

# Client Secret for SP
resource "azuread_service_principal_password" "databricks_sp_secret" {
  service_principal_id = azuread_service_principal.databricks_sp.id
#   value                = random_password.databricks_sp_secret.result
  end_date_relative    = "8760h" # 1 year

  depends_on = [
    azuread_service_principal.databricks_sp,
    data.azuread_service_principal.databricks_sp
  ]
}
# ==================================================
# RBAC (Contributor) for SP on Storage Account (for Databricks access to storage)
resource "azurerm_role_assignment" "databricks_sp_contributor" {
    scope                = azurerm_storage_account.datalake.id
    role_definition_name = "Storage Blob Data Contributor"
    principal_id         = azuread_service_principal.databricks_sp.object_id

    depends_on = [
        azuread_service_principal.databricks_sp,
        azurerm_storage_account.datalake,
        data.azuread_service_principal.databricks_sp
    ]
}
