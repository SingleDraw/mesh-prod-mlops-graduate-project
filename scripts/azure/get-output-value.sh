#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to retrieve output value from tfstate in storage account (using Azure CLI)
# from foundation tfstate 
# and set it as a GitHub secret in the platform repository
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
    error "Usage: $0 <state_key_env_variable_name> <output_variable_name>"
    exit 1
fi

STATE_KEY_NAME="$1"
OUTPUT_VARIABLE_NAME="$2"

# Script .env variables
if [ -z "${SUBSCRIPTION_ID:-}" ] || \
   [ -z "${TFSTATE_STORAGE_ACCOUNT_NAME:-}" ] || \
   [ -z "${TFSTATE_CONTAINER_NAME:-}" ] || \
   [ -z "${!STATE_KEY_NAME:-}" ]; then
    error "One or more required environment variables are not set in .env file."
    error "Please ensure "
    error "  SUBSCRIPTION_ID"
    error "  TFSTATE_STORAGE_ACCOUNT_NAME"
    error "  TFSTATE_CONTAINER_NAME"
    error "  $STATE_KEY_NAME"
    error "are defined in .env."
    exit 1
fi

if ! az account show &>/dev/null; then
    error "Azure CLI is not logged in. Please run 'az login' to authenticate."
    exit 1
fi

az account set --subscription "$SUBSCRIPTION_ID" && \
	az storage blob download \
		--account-name "$TFSTATE_STORAGE_ACCOUNT_NAME" \
		--container-name "$TFSTATE_CONTAINER_NAME" \
		--name "${!STATE_KEY_NAME}" \
		--file /tmp/retrieved.tfstate \
		--auth-mode login &>/dev/null && \
OUTPUT_VALUE="$(jq -r ".outputs.$OUTPUT_VARIABLE_NAME.value" /tmp/retrieved.tfstate)" && \
rm -f /tmp/retrieved.tfstate

if [ -z "$OUTPUT_VALUE" ] || [ "$OUTPUT_VALUE" == "null" ]; then
    error "Failed to retrieve output value from tfstate."
    error "Please check if the state key and output variable name are correct."
    exit 1
fi

# return output value as output for caller to use (e.g. set as GitHub secret)
echo "$OUTPUT_VALUE"
