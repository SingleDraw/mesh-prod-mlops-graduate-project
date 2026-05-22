
data "azurerm_client_config" "current" {}

# --------------------
# UAMI data source (for datastore auth)
# Note: this assumes the UAMI is already created (e.g. by the platform TF code)
# --------------------
data "azurerm_user_assigned_identity" "sa_uami" {
  name                = var.sa_uami_name
  resource_group_name = var.datalake_resource_group_name
}


resource "azurerm_resource_group" "ml" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.ml.name
  location                 = azurerm_resource_group.ml.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # disable soft delete for blobs
  blob_properties {
    delete_retention_policy {
      days    = 1
      permanent_delete_enabled = true
    }
    container_delete_retention_policy {
      days    = 1
    }
  }

  depends_on = [
    azurerm_resource_group.ml
  ]
}

resource "azurerm_application_insights" "ai" {
  name                = var.application_insights_name
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  application_type    = "web"

  depends_on = [azurerm_resource_group.ml]
}

# --------------------
# Key Vault
# --------------------
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true

  # Opcjonalnie: zapobiegaj usuwaniu przy zmianach
  lifecycle {
    prevent_destroy = false
  }

  depends_on = [azurerm_resource_group.ml]
}

# --------------------
# ACR
# --------------------
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  location            = azurerm_resource_group.ml.location
  resource_group_name = azurerm_resource_group.ml.name
  sku                 = "Basic"

  depends_on = [azurerm_resource_group.ml]
}

# --------------------
# ML Workspace
# --------------------
resource "azurerm_machine_learning_workspace" "mlws" {
  name                    = var.workspace_name
  location                = azurerm_resource_group.ml.location
  resource_group_name     = azurerm_resource_group.ml.name

  storage_account_id      = azurerm_storage_account.sa.id
  key_vault_id            = azurerm_key_vault.kv.id
  application_insights_id = azurerm_application_insights.ai.id

  # identity {
  #   type = "SystemAssigned"
  # }

  # identity { # WRONG?
  #   type = "SystemAssigned, UserAssigned"
  #   user_assigned_identity {
  #     id = data.azurerm_user_assigned_identity.sa_uami.id
  #   }
  # }

  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.sa_uami.id]
  }

  depends_on = [
    azurerm_resource_group.ml,
    azurerm_storage_account.sa,
    azurerm_key_vault.kv,
    azurerm_application_insights.ai
  ]
}

# --------------------
# RBAC for ML Workspace to access Key Vault
resource "azurerm_role_assignment" "mlws_kv" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_machine_learning_workspace.mlws.identity[0].principal_id

  depends_on = [
    azurerm_key_vault.kv, 
    azurerm_machine_learning_workspace.mlws
  ]
}

# RBAC for ML Workspace to access Storage Account
resource "azurerm_role_assignment" "mlws_sa" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.mlws.identity[0].principal_id

  # optional: skip AAD check for service principal (useful for testing)
  skip_service_principal_aad_check = true

  # lifecycle {
  #   replace_triggered_by = [azurerm_machine_learning_workspace.mlws]
  # }

  depends_on = [
    azurerm_storage_account.sa, 
    azurerm_machine_learning_workspace.mlws
  ]
}

# RBAC for ML Workspace to ACR pull (for MLOps pipelines)
resource "azurerm_role_assignment" "mlws_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_machine_learning_workspace.mlws.identity[0].principal_id

  depends_on = [
    azurerm_container_registry.acr, 
    azurerm_machine_learning_workspace.mlws
  ]
}

# RBAC for ML Workspace as ML Contributor (for AzureML Studio access and permissions)
resource "azurerm_role_assignment" "mlws_ml_contributor" {
  scope                = azurerm_machine_learning_workspace.mlws.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_machine_learning_workspace.mlws.identity[0].principal_id
  
  lifecycle {
    replace_triggered_by = [azurerm_machine_learning_workspace.mlws]
  }

  depends_on = [
    azurerm_machine_learning_workspace.mlws
  ]
}
