variable "application_id" {
    type        = string
    description = "ID of the application to create credentials for"
}

variable "display_name" {
  type        = string
  description = "Name of the federated credential (e.g. 'github-actions-oidc')"
}

variable "subject" {
    type        = string
    description = "The OIDC subject claim to match for the federated credential (e.g. 'repo:owner/repo:ref:refs/heads/main' for GitHub Actions)"
}

variable "audiences" {
    type        = list(string)
    description = "List of audiences for the federated credential (e.g. ['api://AzureADTokenExchange'] for GitHub Actions OIDC)"
    default     = ["api://AzureADTokenExchange"]
}

variable "issuer" {
    type        = string
    description = "The OIDC issuer URL for the federated credential (e.g. 'https://token.actions.githubusercontent.com' for GitHub Actions)"
    default     = "https://token.actions.githubusercontent.com"
}

