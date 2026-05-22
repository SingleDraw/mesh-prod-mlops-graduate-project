#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to debug repository setup and configuration
# ============================

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/log.sh"

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    error "REPO or KEY_FILE argument is not provided."
    error "Please provide REPO in the format 'owner/repo' and KEY_FILENAME when running this script."
    exit 1
fi

REPO="$1"
KEY_FILENAME="$2"

if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed. Please install it to use this script."
    exit 1
fi

if ! gh auth status &> /dev/null; then
    error "GitHub CLI (gh) is not authenticated. Please run 'gh auth login' to authenticate."
    exit 1
fi

gh secret set SSH_MODULES_PRIVATE_KEY \
	--repo "$REPO" \
	--body "$(cat "./secrets/.ssh/$KEY_FILENAME")" || { \
    error "Failed to set SSH_MODULES_PRIVATE_KEY secret in repository '$REPO'." \
    exit 1; \
}

exit 0