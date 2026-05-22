variable "resource_group_name" {
    description = "Resource group name where the Azure Container Registry (ACR) will be created."
    type        = string
}

variable "container_registry_name" {
    description = "Name of the Azure Container Registry (ACR) to be created. Must be globally unique across Azure."
    type        = string
}

variable "location" {
    description = "Azure region where the Azure Container Registry (ACR) will be created."
    type        = string
}

variable "acr_pullers" {
    description = "List of object IDs of identities (e.g., managed by AKS or SP) that should have pull access to the ACR."
    type        = list(string)
    default     = []
}

variable "acr_pushers" {
    description = "List of object IDs of identities (e.g., SP used by CI/CD) that should have push access to the ACR."
    type        = list(string)
    default     = []
}

variable "tags" {
    description = "Tags to apply to the ACR instance"
    type        = map(string)
    default     = {}
}