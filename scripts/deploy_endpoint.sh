#!/usr/bin/env bash
set -e

if [[ -z "${ENDPOINT_NAME:-}" ]]; then
    echo "ERROR: ENDPOINT_NAME environment variable is not set." >&2
    exit 1
fi

az ml online-endpoint create \
  --file endpoints/endpoint.yml

az ml online-deployment create \
  --file endpoints/deployment.yml

# shellcheck disable=SC2086
az ml online-endpoint update \
  --name $ENDPOINT_NAME \
  --traffic blue=100