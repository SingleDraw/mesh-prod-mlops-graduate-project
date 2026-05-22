resource "github_actions_secret" "secrets" {
  for_each   = { for s in var.github_actions_secrets : s.name => s }
  repository = var.github_repo_name
  secret_name = each.value.name
  plaintext_value = each.value.value
}