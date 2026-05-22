terraform {
  required_version = ">= 1.5.0"
  
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

variable "subscription_id" {
  description = "Subscription ID for the management subscription where role assignments will be created."
  type        = string
}

provider "azurerm" {
  features {}
  alias = "management"
  subscription_id = var.subscription_id
}

provider "azuread" {}

module "test" {
  source = "./modules/test"

  providers = {
    azurerm = azurerm.management
    azuread = azuread
  }
}

output "object_id" {
    value       = module.test.object_id
    description = "Object ID of the current user authenticated with Azure AD. This is used for testing role assignments in this module."
}

output "client_id" {
    value       = module.test.client_id
    description = "Client ID of the current user authenticated with Azure AD. This is used for testing role assignments in this module."
}

output "subscription_id" {
    value       = module.test.subscription_id
    description = "Subscription ID of the current Azure subscription. This is used for testing role assignments in this module."
}

output "tenant_id" {
    value       = module.test.tenant_id
    description = "Tenant ID of the current Azure subscription. This is used for testing role assignments in this module."
}