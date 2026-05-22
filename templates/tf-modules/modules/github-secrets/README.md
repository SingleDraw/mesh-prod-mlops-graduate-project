
# GitHub Secrets Module requires provider configuration:
provider "github" {
  token = var.github_token
  owner = var.github_repo_owner
}

# Example usage:
module "github_secrets" {
    source = "./modules/github-secrets"
    
    github_repo_name = "my-repo"
    
    github_actions_secrets = [
        {
            name  = "AZURE_TENANT_ID",
            value = var.azure_tenant_id
        },
        {
            name  = "AZURE_CLIENT_ID",
            value = var.azure_client_id
        },
        {
            name  = "AZURE_CLIENT_SECRET",
            value = var.azure_client_secret
        }
    ]
}