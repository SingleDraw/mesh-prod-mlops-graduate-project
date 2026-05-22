provider "azuread" {}

provider "azurerm" {
    features {}
    subscription_id = var.subscription_id

    # must be set to true 
    # if storage has shared_access_key = false, 
    # which is recommended for security reasons
    storage_use_azuread = true
}
