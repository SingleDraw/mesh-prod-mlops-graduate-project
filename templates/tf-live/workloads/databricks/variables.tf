
variable "datalake_resource_group_name" {
  description = "Name of the resource group where the existing datalake storage account is located"
}

variable "datalake_storage_account_name" {
  description = "Name of the existing storage account to use as datalake for Databricks"
}

variable "location" {
  default = "westeurope"
}

variable "prefix" {
  default = "dbx-demo"
}

variable "subscription_id" {}