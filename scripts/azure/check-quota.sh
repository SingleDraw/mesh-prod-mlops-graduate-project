#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SUB_ID:-}" ]; then
  echo "SUB_ID environment variable is not set. Please set it to your Azure subscription ID."
  exit 1
fi

if [ -z "${LOCATION:-}" ]; then
  echo "LOCATION environment variable is not set. Please set it to your Azure region (e.g., eastus, westus2, germanywestcentral)."
  exit 1
fi

retry_quota() {
  local n=0
  local max=5
  local delay=5

  until [ $n -ge $max ]
  do
    # shellcheck disable=SC2086
    az quota list \
        --scope /subscriptions/$SUB_ID/providers/Microsoft.Compute/locations/$LOCATION \
        --query "[?properties.limit.value!=null].{name:(name.value || name), limit:properties.limit.value, usage:properties.currentValue}" \
        -o table \
      && break

    n=$((n+1))
    sleep $delay
  done

  if [ $n -ge $max ]; then
    echo "Quota API failed after retries"
    exit 1
  fi
}

if ! command -v az &> /dev/null; then
  echo "Azure CLI is not installed. Please install it to use this script."
  exit 1
fi

if ! az account show &> /dev/null; then
  echo "Azure CLI is not authenticated. Please run 'az login' to authenticate."
  exit 1
fi

retry_quota