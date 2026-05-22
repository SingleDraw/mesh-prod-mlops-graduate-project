
# ========= General Variables ==========

variable "subscription_id" {
  description = "Azure Subscription ID where the resources will be provisioned"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to create"
  type        = string
}

variable "location" {
  description = "Azure region where the resources will be created"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the Azure Storage Account to create"
  type        = string
}

# ========= UAMI for Storage Access (not used in Databricks) ==========
variable "sa_uami_name" {
  description = "Name for the User Assigned Managed Identity (UAMI) that will be used for storage access by Databricks and AKS"
  type        = string
}

# ========= Unity Access Connector for Databricks ==========
variable "prefix" {
  description = "Prefix for naming resources (e.g. resource group, storage account, databricks workspace)"
  type        = string
}
