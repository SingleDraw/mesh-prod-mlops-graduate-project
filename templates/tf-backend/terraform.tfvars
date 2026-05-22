# ============================================================================
# Foundation Service Principal 
# ============================================================================
oidc_subject = "{{OIDC_SUBJECT}}"   # e.g. "repo:my-org/my-repo:ref:refs/heads/main" for GitHub Actions OIDC subject claim
oidc_subject_databricks = "{{OIDC_SUBJECT_DATABRICKS}}"   # e.g. "repo:my-org/my-repo:ref:refs/heads/main" for GitHub Actions OIDC subject claim
oidc_subject_azureml = "{{OIDC_SUBJECT_AZUREML}}"   # e.g. "repo:my-org/my-repo:ref:refs/heads/main" for GitHub Actions OIDC subject claim

# ============================================================================
# Security settings
# ============================================================================

# White list IPs for accessing Storage Account (state backend)
allowed_ip_addresses = []          # will be set by http data source 
                                   # to current IP (see locals.tf)

# RBAC for Storage Account
storage_contributors      = []     # Optionally: Object IDs of users with access to state
disable_shared_access_key = true   # should be true if using Azure AD auth

# HTTPS
enable_https_only = true           # Enforce HTTPS for connections

# ============================================================================
# Resource tags
# ============================================================================
tags = {
  project    = "{{PROJECT_NAME}}"
  deployedBy = "{{DEPLOYED_BY}}"
  owner      = "{{OWNER}}"           # resource owner (team or individual)
}
