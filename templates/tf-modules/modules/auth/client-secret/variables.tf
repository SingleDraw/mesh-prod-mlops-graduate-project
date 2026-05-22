variable "service_principal_id" {
    type        = string
    description = "The ID of the service principal to create the client secret for. This should be the ID of the service principal created in the service-principal module."
}

# ---
# # application variable used as alternative to service principal for creating client secret, but it's more common to create secrets for service principals directly
# variable "application_id" {
#     type        = string
#     description = "The ID of the Azure AD application to create the client secret for. This should be the application ID from the service principal module."
# }
# ---

variable "create_client_secret" {
    type        = bool
    description = "Whether to create a client secret for the service principal. For production, it's recommended to use federated credentials with GitHub Actions OIDC instead of client secrets for better security. In development, you can use a client secret for simplicity."
    default     = false
}

variable "client_secret_name" {
    type        = string
    description = "The display name for the client secret. This is used to identify the secret in Azure AD. It can be helpful to include the application name and environment in the secret name for clarity."
    default     = "Terraform Client Secret"
}

variable "end_date_relative" {
    type        = string
    description = "The relative end date for the client secret (e.g. '8760h' for 1 year). To renew, run terraform apply again before expiration."
    default     = "8760h"
}

# output path for saving credentials to file (dev)
variable "local_file_path" {
    type        = string
    description = "The local file path to save the client secret credentials for development use. If not provided, saving to a local file will be skipped. This file should be added to .gitignore to avoid committing sensitive information. For production, consider using GitHub Actions secrets instead of a local file."
    default     = ""
}

variable "client_data" {
    type = object({
        tenant_id       = string
        client_id       = string
        subscription_id = string
        # object_id       = string
    })

    description = "An object containing the client data to be saved for development use along with created client secret. This includes tenant ID, client ID, subscription ID, and object ID. This data can be used to set environment variables for local development or local runner workflows."

    default = {
        tenant_id       = ""
        client_id       = ""
        subscription_id = ""
        # object_id       = ""
    }

    # validate only known fields (to avoid plan errors)
    validation {
        condition     = var.client_data.subscription_id != ""
        error_message = "subscription_id must be provided"
    }
}