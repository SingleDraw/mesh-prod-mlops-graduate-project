resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  https_traffic_only_enabled        = var.enable_https_only
  shared_access_key_enabled         = !var.disable_shared_access_key
  min_tls_version                   = "TLS1_2"
  infrastructure_encryption_enabled = true

  # Security enhancements
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  # blob_properties {
  #   versioning_enabled  = true
  #   change_feed_enabled = true

  #   delete_retention_policy {
  #     days = 30
  #   }

  #   container_delete_retention_policy {
  #     days = 30
  #   }
  # }

  tags = var.tags
}

# Network rules: default deny z white listą IP
resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id = azurerm_storage_account.this.id

  bypass                     = ["AzureServices"]

  # Option 1: Default deny, whitelist only (bardziej restrykcyjne, wymaga aktualizacji reguł przy zmianie IP)
  # default_action             = "Deny" # Default deny - whitelist only
  # ip_rules                   = var.allowed_ip_addresses

  # Option 2: Default allow, whitelist + RBAC for auth (mniej restrykcyjne, ale wygodniejsze dla dynamicznych IP i użytkowników)
  default_action             = "Allow"  # open to all, RBAC handles auth
  virtual_network_subnet_ids = []
}

# RBAC: Storage Blob Data Contributor dla wybranych użytkowników/grup
resource "azurerm_role_assignment" "storage_contributor" {
  count                = length(var.storage_contributors) > 0 ? length(var.storage_contributors) : 0
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.storage_contributors[count.index]
}

# Utwórz container tylko jeśli nazwa jest podana
resource "azurerm_storage_container" "container" {
  count                 = var.container_name != "" ? 1 : 0
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}
