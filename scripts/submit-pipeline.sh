#!/usr/bin/env bash
set -e

az ml job create \
  --file pipelines/iris-pipeline.yml \
  --stream