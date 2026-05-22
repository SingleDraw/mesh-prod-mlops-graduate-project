
# ========= General Resource Outputs ==========

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "storage_account_id" {
  value = azurerm_storage_account.datalake.id
}

# ========= UAMI Outputs (not used in Databricks) ==========

output "uami_id" {
  value = azurerm_user_assigned_identity.sa_uami.id
}

output "uami_name" {
  value = azurerm_user_assigned_identity.sa_uami.name
}

output "uami_client_id" {
  value = azurerm_user_assigned_identity.sa_uami.client_id
}

output "uami_principal_id" {
  value = azurerm_user_assigned_identity.sa_uami.principal_id
}

# ======== Service Principal for Databricks Outputs =========
output "databricks_sp_client_id" {
  value = azuread_service_principal.databricks_sp.client_id
}

output "databricks_sp_client_secret" {
  value = azuread_service_principal_password.databricks_sp_secret.value
  sensitive = true
}



