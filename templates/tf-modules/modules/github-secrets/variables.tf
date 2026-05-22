variable "github_repo_name" {
  type        = string
  description = "Name of the GitHub repository where secrets will be created"
}

variable "github_actions_secrets" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "List of GitHub Actions secrets to create"
}