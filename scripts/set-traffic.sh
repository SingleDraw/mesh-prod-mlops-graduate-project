#!/usr/bin/env bash
set -e

# Gradual rollout (safe strategy)
# # step 1
# blue=90 green=10
# # step 2
# blue=70 green=30
# # step 3
# blue=50 green=50
# # step 4
# blue=0 green=100


if [[ -z "${ENDPOINT_NAME:-}" ]]; then
    echo "ERROR: ENDPOINT_NAME environment variable is not set." >&2
    exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <blue_traffic_percentage> <green_traffic_percentage>" >&2
    exit 1
fi

BLUE_TRAFFIC=${1:-90}
GREEN_TRAFFIC=${2:-10}

# shellcheck disable=SC2086
az ml online-endpoint update \
  --name $ENDPOINT_NAME \
  --traffic blue=$BLUE_TRAFFIC green=$GREEN_TRAFFIC