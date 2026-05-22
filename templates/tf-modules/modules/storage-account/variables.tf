variable "name" {
  type        = string
  description = "Nazwa Storage Account (globalnie unikalna, 3-24 znaki, lowercase)"
}

variable "resource_group_name" {
  type        = string
  description = "Nazwa Resource Group"
}

variable "location" {
  type        = string
  description = "Lokalizacja zasobu"
}

variable "container_name" {
  type        = string
  description = "Blob container name. If empty, container will not be created."
  default     = ""
}

variable "allowed_ip_addresses" {
  type        = list(string)
  description = "Lista IP adresów które mogą uzyskać dostęp do storage account. Np. ['203.0.113.42', '198.51.100.7']"
  default     = []
}

variable "disable_shared_access_key" {
  type        = bool
  description = "Wyłącz dostęp poprzez Storage Access Key. Uwaga: może utrudnić terraform operations bez RBAC. Rekomendacja: używać z Service Principal."
  default     = true


  # if disable_shared_access_key is true,
  # these settings will be applied to storage account and backend config:

  # Provider configuration:
  # provider "azurerm" {
  #   storage_use_azuread = true
  #   features {}
  # }

  # Backend configuration for terraform:
  # terraform { # or in --backend-config="use_azuread_auth=true" when initializing backend
  #   backend "azurerm" {
  #     storage_use_azuread = true
  #     # other backend config...
  #   }
  # }

  # remote state data source configuration:
  # data "terraform_remote_state" "example" {
  #   backend = "azurerm"
  #   config = {
  #     storage_use_azuread = true
  #     # other config...
  #   }
  # }
}

variable "storage_contributors" {
  type        = list(string)
  description = "Lista Object IDs (użytkownicy/grupy Azure AD) które będą mieć rolę 'Storage Blob Data Contributor'. Np. ['12345678-1234-1234-1234-123456789012']"
  default     = []
}

variable "enable_https_only" {
  type        = bool
  description = "Wymuszaj HTTPS dla wszystkich połączeń"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tagi stosowane do zasobów"
  default     = {}
}
