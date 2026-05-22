
# this user is service principal that needs dbx rbac
data "azurerm_client_config" "current" {}

# ========= Reference Shared Storage Account =========
data "azurerm_storage_account" "datalake" {
  name                = var.datalake_storage_account_name
  resource_group_name = var.datalake_resource_group_name
}

# ========== Resource Group Data Engineering ==========
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# ========== Databricks Workspace ==========
resource "azurerm_databricks_workspace" "dbw" {
  name                = "${var.prefix}-workspace"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}

# ========== Output Workspace URL for convenience ==========
output "databricks_url" {
  value = azurerm_databricks_workspace.dbw.workspace_url
}
