#!/usr/bin/env bash
set -e

if [[ -z "${ENDPOINT_NAME:-}" ]]; then
    echo "ERROR: ENDPOINT_NAME environment variable is not set." >&2
    exit 1
fi

# Optionally specify deployment name (default to 'blue' if not provided)
DEPLOYMENT_NAME=${1:-blue}

# shellcheck disable=SC2086
az ml online-endpoint delete \
  --endpoint-name $ENDPOINT_NAME \
  --name $DEPLOYMENT_NAME \
  --yes