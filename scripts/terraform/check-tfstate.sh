#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to check if Terraform state is stored remotely or locally
# Usage: ./check-tfstate.sh <storage_account_name> <container_name> <state_key>
# Output: "remote" if state is in Azure Blob Storage, "local" if not found
# ============================

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <storage_account_name> <container_name> <state_key>"
    exit 1
fi

if [ -z "${ARM_SUBSCRIPTION_ID:-}" ]; then
    echo "Error: ARM_SUBSCRIPTION_ID environment variable is not set."
    exit 1
fi

if ! az account show &>/dev/null; then
    echo "Azure CLI is not logged in. Please run 'az login' to authenticate."
    exit 1
fi

STORAGE_ACCOUNT_NAME="$1"
CONTAINER_NAME="$2"
STATE_KEY="$3"

az account set --subscription "$ARM_SUBSCRIPTION_ID" >/dev/null

# FAST CHECK: storage account exists (ARM API, no DNS to blob)
if ! az storage account show \
    --name "$STORAGE_ACCOUNT_NAME" \
    --query "name" \
    -o tsv &>/dev/null; then
    echo "local"
    exit 0
fi

# FAST CHECK: container exists (still ARM-backed, faster fail)
if ! az storage container show \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --name "$CONTAINER_NAME" \
    --auth-mode login \
    --query "name" \
    -o tsv &>/dev/null; then
    echo "local"
    exit 0
fi

# ONLY NOW hit blob endpoint (safe)
if az storage blob list \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$CONTAINER_NAME" \
    --auth-mode login \
    --prefix "$STATE_KEY" \
    --num-results 1 \
    --query "[0].name" \
    -o tsv | grep -q "$STATE_KEY"; then
    echo "remote"
else
    echo "local"
fi

# -- end of script --