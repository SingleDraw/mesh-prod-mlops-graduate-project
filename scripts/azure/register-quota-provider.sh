#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to register Azure subscription for quota management
# ============================

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <subscription_id>"
    exit 1
fi

SUBSCRIPTION_ID="$1"

if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it to use this script."
    exit 1
fi

if ! az account show &> /dev/null; then
    echo "Azure CLI is not authenticated. Please run 'az login' to authenticate."
    exit 1
fi


az account set --subscription "$SUBSCRIPTION_ID" && \
az extension add --name quota || true && \
az provider register --namespace Microsoft.Quota


while ! az provider show \
		--namespace Microsoft.Quota \
		--query registrationState \
        -o tsv | grep -q "Registered"; do
    echo "Waiting for Microsoft.Quota provider to be registered..."
    sleep 5
done

echo "Microsoft.Quota provider is registered successfully."