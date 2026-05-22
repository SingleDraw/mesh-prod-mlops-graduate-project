# =======================================================================
# Terraform Service Principal
# =======================================================================
variable "application_name" {
  description = "Nazwa aplikacji dla utworzonego service principal."
  type        = string
  default     = "sp-terraform-application"
}

variable "client_secret_end_date_relative" {
  description = "Relative end date for the client secret (e.g. '8760h' for 1 year). Only used in dev environment when creating a client secret. Ignored in prod where federated credentials are used."
  type        = string
  default     = null
}

# =======================================================================
# provider configuration variables
# =======================================================================
variable "subscription_id" {
    description = "Azure subscription ID where the Terraform state resource group and storage account will be created."
    type        = string
}

# =======================================================================
# Backend state storage settings
# =======================================================================
# resource group variables
variable "resource_group_name" {
    description = "Terraform state resource group name."
    type        = string
    default     = "aimlops-tfstate-rg"
}

variable "location" {
    description = "Azure region where resources will be created (e.g., 'eastus', 'westeurope')."
    type        = string
    default     = "germanywestcentral"
}

# storage account variables
# must be globally unique across Azure, so no default value provided
variable "storage_account_name" {
    type    = string
}

variable "container_name" {
    type    = string
    default = "tfstate"
}

# =======================================================================
# Security settings
# =======================================================================
variable "allowed_ip_addresses" {
  type        = list(string)
  description = "List of IP addresses allowed to access the storage account. E.g., ['203.0.113.42', '198.51.100.7']"
  default     = []
}

variable "disable_shared_access_key" {
  type        = bool
  description = "Disable access via Storage Access Key. Note: may hinder terraform operations without RBAC. Recommendation: use with Service Principal."
  default     = true
}

variable "storage_contributors" {
  type        = list(string)
  description = "List of Object IDs (users/groups in Azure AD) that will have the 'Storage Blob Data Contributor' role. E.g., ['12345678-1234-1234-1234-123456789012']"
  default     = []
}

variable "enable_https_only" {
  type        = bool
  description = "Enforce HTTPS for all connections"
  default     = true
}

# =======================================================================
# Resource tags
# =======================================================================
variable "tags" {
  type        = map(string)
  description = "Tags applied to resources"
  default     = {}
}

# --------------------------------
# OIDC federated credential variables
# --------------------------------
variable "oidc_issuer" {
  type        = string
  description = "The OIDC issuer URL for the federated credential (e.g. 'https://token.actions.githubusercontent.com' for GitHub Actions)"
  default     = "https://token.actions.githubusercontent.com"
}

variable "oidc_subject" {
  type        = string
  description = "The OIDC subject claim for the federated credential (e.g. 'repo:myorg/myrepo:ref:refs/heads/main' for GitHub Actions)"
}

variable "oidc_subject_databricks" {
  type        = string
  description = "The OIDC subject claim for the federated credential (e.g. 'repo:myorg/myrepo:ref:refs/heads/main' for GitHub Actions)"
}

variable "oidc_subject_azureml" {
  type        = string
  description = "The OIDC subject claim for the federated credential (e.g. 'repo:myorg/myrepo:ref:refs/heads/main' for GitHub Actions)"
}

variable "oidc_audiences" {
  type        = list(string)
  description = "List of audiences for the federated credential (e.g. ['api://AzureADTokenExchange'] for GitHub Actions OIDC)"
  default     = ["api://AzureADTokenExchange"]
}

variable "oidc_credential_name" {
  type        = string
  description = "Name of the federated credential (e.g. 'github-actions-oidc')"
  default     = "github-actions-oidc"
}

