#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to push Terraform state file to Azure Storage Account using Azure CLI
# ============================

BOOT_PATH="$1"
SUBSCRIPTION_ID="$2"
TFSTATE_RG_NAME="$3"
TFSTATE_STORAGE_ACCOUNT_NAME="$4"
TFSTATE_CONTAINER_NAME="$5"
TFSTATE_KEY="$6"

if  [ -z "$BOOT_PATH" ] || \
    [ -z "$SUBSCRIPTION_ID" ] || \
    [ -z "$TFSTATE_RG_NAME" ] || \
    [ -z "$TFSTATE_STORAGE_ACCOUNT_NAME" ] || \
    [ -z "$TFSTATE_CONTAINER_NAME" ] || \
    [ -z "$TFSTATE_KEY" ]; then
    echo "Usage: $0 <bootstrap-repo-path> <subscription-id> <tfstate-rg-name> <tfstate-storage-account-name> <tfstate-container-name> <tfstate-key>"
    exit 1
fi

# shellcheck disable=SC2086
echo "Pushing local Terraform state to remote backend..." && \
$BOOT_PATH/toggle-backend.sh "disable" "$BOOT_PATH" && \
( cd $BOOT_PATH && terraform state pull > local.tfstate ) && \
$BOOT_PATH/toggle-backend.sh "enable" "$BOOT_PATH" && \
(   cd $BOOT_PATH && \
    export ARM_USE_AZUREAD=true && \
	export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID && \
	yes | terraform init \
        -upgrade -reconfigure \
        -backend-config="resource_group_name=$TFSTATE_RG_NAME" \
        -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT_NAME" \
        -backend-config="container_name=$TFSTATE_CONTAINER_NAME" \
        -backend-config="key=$TFSTATE_KEY" && \
	terraform state push -force local.tfstate && \
	rm -f local.tfstate \
)
