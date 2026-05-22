output "id" {
  value       = azurerm_storage_account.this.id
  description = "Storage Account ID"
}

output "name" {
  value       = azurerm_storage_account.this.name
  description = "Nazwa Storage Account"
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.this.primary_blob_endpoint
  description = "Primary blob endpoint"
}

output "https_only_enabled" {
  value       = azurerm_storage_account.this.https_traffic_only_enabled
  description = "HTTPS only enabled status"
}

output "shared_access_key_enabled" {
  value       = azurerm_storage_account.this.shared_access_key_enabled
  description = "Shared Access Key enabled status"
}

output "primary_access_key" {
  value       = var.disable_shared_access_key ? null : azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  value       = var.disable_shared_access_key ? null : azurerm_storage_account.this.secondary_access_key
  sensitive   = true
}
