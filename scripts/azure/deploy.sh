#!/bin/bash
set -euo pipefail

RG="rg-ml-prod"
WS="ml-workspace-prod"
ENDPOINT="ml-endpoint-prod"

az extension add -n ml -y

# endpoint: create OR ignore if exists
az ml online-endpoint create \
  --name $ENDPOINT \
  --resource-group $RG \
  --workspace-name $WS \
  --only-show-errors \
  2>/dev/null || true

# # 2. deploy model
# az ml online-deployment create \
#   --file ml/deployment.yml \
#   --resource-group $RG \
#   --workspace-name $WS

# deployment: REPLACE instead of create
az ml online-deployment update \
  --file ml/deployment.yml \
  --resource-group $RG \
  --workspace-name $WS

# 3. traffic shift (blue/green)
az ml online-endpoint update \
  --name $ENDPOINT \
  --traffic "blue=100"