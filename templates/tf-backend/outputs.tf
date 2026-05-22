output "azure_account" {
  value = {
    description     = "Bootstrap Azure account used for Terraform backend configuration"
    client_id       = data.azurerm_client_config.current.client_id
    tenant_id       = data.azurerm_client_config.current.tenant_id
    subscription_id = data.azurerm_client_config.current.subscription_id
  }
}

output "user_object_id" {
  value = data.azurerm_client_config.current.object_id
}

output "terraform_sp_client_id" {
  value = module.terraform_sp.client_id
}

output "terraform_sp_client_secret" {
  value = module.client_secret.client_secret
  sensitive = true
}