include .env

include make/Config.mk
include make/Utils.mk

# Terraform
include make/Terraform/TfModulesRepo.mk
include make/Terraform/TfBackendRepo.mk
include make/Terraform/TfLiveRepo.mk

# AzureML
include make/AzureML/AzureML-dev.mk
include make/AzureML/AzureML-deploy.mk
include make/AzureML/AzureML-docker.mk
include make/AzureML/AzureML-runtime.mk

# Databricks
include make/Databricks/Databricks-deploy.mk
include make/Databricks/Databricks-runtime.mk
include make/Databricks/_Debug.mk

# Local Development
include make/Local/JupyterLab.mk


# ==========================
#
# * Terraform Provisioning
# make generate-modules-repo
# make generate-bootstrap
# make generate-live-repo
# make trigger-live-platform-ci
# make trigger-live-workload-dbx-ci
# make trigger-live-workload-azureml-ci
#
# ==========================
#
# * Databricks
# make generate-databricks-repo
# make trigger-upload-xlsx-workflow
# make trigger-dbx-cd-workflow
#
# ==========================
#
# * AzureML
# make store-datalake-client-creds-azureml
# make generate-azureml-repo
# make trigger-azureml-workflow-upload-mltable
# make trigger-azureml-workflow-datalake-registration
# make trigger-azureml-workflow-delta-resource-registration
# make trigger-azureml-workflow-submit-delta-pipeline
#
# ==========================
# Destroying Infrastructure
# make trigger-destroy-workload-dbx-ci
# make trigger-destroy-workload-azureml-ci
# make trigger-destroy-platform-ci

# ==========================
# Debugging (tf state unlock)
# make tf-dbx-unlock-state DATABRICKS_LOCK_ID=<lock_id>
