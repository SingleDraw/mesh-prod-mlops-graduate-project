#!/usr/bin/env bash
set -e

if [[ -z "${ENDPOINT_NAME:-}" ]]; then
    echo "ERROR: ENDPOINT_NAME environment variable is not set." >&2
    exit 1
fi

az ml online-endpoint create \
  --file endpoints/endpoint.yml

# deploy BLUE (current stable)
az ml online-deployment create \
  --file endpoints/deployment-blue.yml

# route 100% to blue
az ml online-endpoint update \
  --name iris-endpoint \
  --traffic blue=100

# deploy GREEN (new version)
az ml online-deployment create \
  --file endpoints/deployment-green.yml