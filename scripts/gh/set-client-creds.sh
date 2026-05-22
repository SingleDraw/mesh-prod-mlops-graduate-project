#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to set Client Credentials 
# in GitHub Secrets for Terraform Cloud OIDC integration
# ============================

# load env
set -a;
# shellcheck disable=SC1091
source .env
set +a

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/log.sh"


# Ensure state key variable name argument is provided by the caller
if [ $# -ne 2 ]; then
    error "Usage: $0 <client_id> <owner/repo>"
    exit 1
fi

CLIENT_ID="$1"
REPO="$2"

# Script .env variables
if [ -z "${SUBSCRIPTION_ID:-}" ] || \
   [ -z "${TENANT_ID:-}" ]; then
    error "One or more required environment variables are not set in .env file."
    error "Please ensure the following variables are defined in .env:"
    error "  SUBSCRIPTION_ID"
    error "  TENANT_ID"
    exit 1
fi

gh secret set ARM_TENANT_ID \
        --repo "$REPO" \
        --body "$TENANT_ID" \
        && \
gh secret set ARM_SUBSCRIPTION_ID \
        --repo "$REPO" \
        --body "$SUBSCRIPTION_ID" \
        && \
gh secret set ARM_CLIENT_ID \
        --repo "$REPO" \
        --body "$CLIENT_ID" \
        && \
ok "ARM_CLIENT_ID=$CLIENT_ID" && \
ok "set as secret in $REPO."

# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
    error "Failed to set GitHub secrets."
    exit 1
fi