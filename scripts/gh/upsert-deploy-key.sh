#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to debug repository setup and configuration
# ============================

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/log.sh"

if [ $# -ne 3 ]; then
    error "Usage: $0 <owner/repo> <key_name> <key_file_name.pub>"
    exit 1
fi

REPO="$1"
KEY_NAME="$2"
KEY_FILE_NAME="$3"


if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed. Please install it to use this script."
    exit 1
fi

if ! gh auth status &> /dev/null; then
    error "GitHub CLI (gh) is not authenticated. Please run 'gh auth login' to authenticate."
    exit 1
fi

# Delete any existing deploy keys with the same name to avoid conflicts
log "Deleting deploy keys matching '$KEY_NAME' from $REPO..."
(gh repo deploy-key list --repo "$REPO" | \
	grep "$KEY_NAME" | \
	awk '{print $1}' | \
	xargs -I {} gh repo deploy-key delete {} --repo "$REPO" ) \
    || warn "No deploy keys to delete in $REPO."

gh repo deploy-key add "./secrets/.ssh/$KEY_FILE_NAME".pub \
	--repo "$REPO" \
	--title "$KEY_NAME"

# -- end of script --