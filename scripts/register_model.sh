#!/usr/bin/env bash
set -e

JOB_NAME=$1

# shellcheck disable=SC2086
az ml model create \
  --name iris-classifier \
  --path azureml://jobs/${JOB_NAME}/outputs/pipeline_output \
  --type custom_model