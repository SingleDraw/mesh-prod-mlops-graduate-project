#!/usr/bin/env bash
set -euo pipefail

# ============================
# Set GitHub Repository Variables or Secrets using GitHub CLI (gh)
# ============================

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/log.sh"

if [ -z "${REPO:-}" ]; then
    error "REPO environment variable is not set."
    error "Please set REPO to the format 'owner/repo' before running this script."
    exit 1
fi

# determine if we're setting secrets or variables 
# based on the SECRET environment variable
SECRET=${SECRET:-false}

if [ "$SECRET" = false ]; then
    # shellcheck disable=SC2034
    VARTYPE="variable"
else
    # shellcheck disable=SC2034
    VARTYPE="secret"
fi

if [ "$#" -lt 2 ] || [ $(($# % 2)) -ne 0 ]; then
    echo "Usage: $0 <${VARTYPE}-name1> <${VARTYPE}-value1> [<${VARTYPE}-name2> <${VARTYPE}-value2> ...]"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed. Please install it to use this script."
    exit 1
fi

if ! gh auth status &> /dev/null; then
    error "GitHub CLI (gh) is not authenticated. Please run 'gh auth login' to authenticate."
    exit 1
fi

while [ "$#" -gt 0 ]; do
    SECRET_NAME="$1"
    SECRET_VALUE="$2"
    shift 2

    if [ -z "$SECRET_NAME" ] || [ -z "$SECRET_VALUE" ]; then
        error "$VARTYPE name and value cannot be empty. Skipping."
        exit 1
    fi

    if [ "$SECRET" = true ]; then
        if ! gh secret set "$SECRET_NAME" \
            --repo "$REPO" \
            --body "$SECRET_VALUE"; then
            error "Failed to set secret '$SECRET_NAME' in repository '$REPO'."
            exit 1
        fi
    else
        if ! gh variable set "$SECRET_NAME" \
            --repo "$REPO" \
            --body "$SECRET_VALUE"; then
            error "Failed to set variable '$SECRET_NAME' in repository '$REPO'."
            exit 1
        fi
    fi
done

ok "All $VARTYPE(s) set successfully in repository '$REPO'."