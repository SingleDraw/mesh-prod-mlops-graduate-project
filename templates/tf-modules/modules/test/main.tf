terraform {
  required_version = ">= 0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }

    azuread = {
        source  = "hashicorp/azuread"
        version = "~> 2.47"
    }
  } 
}

# client config for current user
data "azuread_client_config" "current" {}

output "object_id" {
    value       = data.azuread_client_config.current.object_id
    description = "Object ID of the current user authenticated with Azure AD. This is used for testing role assignments in this module."
}

output "client_id" {
    value       = data.azuread_client_config.current.client_id
    description = "Client ID of the current user authenticated with Azure AD. This is used for testing role assignments in this module."
}

# current subscription
data "azurerm_subscription" "current" {}

output "subscription_id" {
    value       = data.azurerm_subscription.current.subscription_id
    description = "Subscription ID of the current Azure subscription. This is used for testing role assignments in this module."
}

# tenant data
data "azurerm_client_config" "current" {}

output "tenant_id" {
    value       = data.azurerm_client_config.current.tenant_id
    description = "Tenant ID of the current Azure subscription. This is used for testing role assignments in this module."
}