#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to debug repository setup and configuration
# ============================

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/log.sh"

if [ -z "${1:-}" ]; then
    error "REPO argument is not provided."
    error "Please provide REPO in the format 'owner/repo' when running this script."
    exit 1
fi

REPO="$1"

if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed. Please install it to use this script."
    exit 1
fi

if ! gh auth status &> /dev/null; then
    error "GitHub CLI (gh) is not authenticated. Please run 'gh auth login' to authenticate."
    exit 1
fi

gh secret list --repo "$REPO"
gh variable list --repo "$REPO"
gh repo deploy-key list --repo "$REPO"


