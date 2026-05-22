#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to generate an SSH key pair for GitHub repository access
# ============================

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/log.sh"

SECRETS_DIR=${SECRETS_DIR:-"./secrets/.ssh"}

mkdir -p "$SECRETS_DIR"

if [ $# -ne 2 ]; then
    error "Usage: $0 <key_file> <key_name>"
    exit 1
fi

key_name="$1"
key_file="$2"

ok "Generating SSH key pair '$key_file'..." && \
(yes | ssh-keygen -t ed25519 \
    -f "$SECRETS_DIR/${key_file}" \
    -N "" \
    -C "${key_name}") && \
ok "SSH key pair generated: $SECRETS_DIR/${key_file} and $SECRETS_DIR/${key_file}.pub"

# # shellcheck disable=SC2181
# if [ $? -ne 0 ]; then
#     error "Failed to generate $key_file SSH key pair."
#     exit 1
# fi

exit 0

# -- end of script --