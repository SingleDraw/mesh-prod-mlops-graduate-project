variable "subscription_id" {
    description = "Azure Subscription ID where resources will be created."
    type        = string
}


# =============================
# Deltalake UAMI variables
# =============================
variable "sa_uami_name" {
    description = "Name of the User Assigned Managed Identity (UAMI) to be used for authenticating Azure ML datastores. This UAMI should already exist and have appropriate permissions (e.g., Storage Blob Data Contributor) on the storage account."
    type        = string
}

variable "datalake_resource_group_name" {
    description = "Name of the Azure Resource Group where the datalake storage account is located. This is needed to reference the existing UAMI for datastore authentication."
    type        = string
}

# =============================
# Globally unique resource names
# =============================
variable "storage_account_name" {
    description = "Name of the Azure Storage Account to be created. Must be globally unique and between 3-24 characters, using only lowercase letters and numbers."
    type        = string
}

variable "key_vault_name" {
    description = "Name of the Azure Key Vault to be created. Must be globally unique and between 3-24 characters, using only lowercase letters and numbers."
    type        = string
}

variable "acr_name" {
    description = "Name of the Azure Container Registry to be created. Must be globally unique and between 5-50 characters, using only lowercase letters and numbers."
    type        = string
}

variable "endpoint_name" {
    description = "Name of the Azure Machine Learning Online Endpoint to be created. Must be globally unique across Azure, between 3-63 characters, and can contain lowercase letters, numbers, and hyphens."
    type        = string
}

# =============================
# Resource Group and Location variables
# =============================
variable "resource_group_name" {
    description = "Name of the Azure Resource Group where resources will be created."
    type        = string
    default     = "rg-ml-prod"
}

variable "location" {
    description = "Azure region for resource deployment. Examples: 'eastus', 'westeurope', 'germanywestcentral'."
    type        = string
}


# =============================
# ML Workspace variables
# =============================
variable "workspace_name" {
    description = "Name of the Azure Machine Learning Workspace to be created."
    type        = string
    default     = "ml-workspace-prod"
}

variable "application_insights_name" {
    description = "Name of the Azure Application Insights resource to be created."
    type        = string
    default     = "ml-ai-prod"
}

# =============================
# ML Compute Cluster variables
# =============================
variable "compute_cluster_name" {
    description = "Name of the Azure Machine Learning Compute Cluster to be created."
    type        = string
    default     = "cpu-cluster"
}

variable "compute_cluster_vm_size" {
    description = "VM size for the Azure Machine Learning Compute Cluster."
    type        = string
    default     = "Standard_D2as_v4"
}