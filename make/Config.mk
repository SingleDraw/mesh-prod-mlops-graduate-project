
# batch line endings fix targets
TARGETS 	:= .env

# ==========================
# Repository Configuration

# Modules Repository Configuration
GH_REPO_MODULES  		:= $(PROJECT_NAME)-terraform-modules
GH_REPO_MODULES_REF		:= v1.0.0

# Live Repository Configuration
GH_REPO_LIVE  			:= $(PROJECT_NAME)-terraform-live
GH_REPO_LIVE_BRANCH 	:= main

# AzureML Repository Configuration
GH_REPO_AZUREML			:= $(PROJECT_NAME)-azureml
GH_REPO_AZUREML_BRANCH	:= main

# Databricks Repository Configuration
GH_REPO_DATABRICKS			:= $(PROJECT_NAME)-databricks
GH_REPO_DATABRICKS_BRANCH	:= main

# Full repo names with owner
MODULES_REPO			:= $(GH_OWNER)/$(GH_REPO_MODULES)
LIVE_REPO				:= $(GH_OWNER)/$(GH_REPO_LIVE)
AZUREML_REPO			:= $(GH_OWNER)/$(GH_REPO_AZUREML)
DATABRICKS_REPO			:= $(GH_OWNER)/$(GH_REPO_DATABRICKS)

# template vars
MODULES_URL 	:= git@github.com:$(GH_OWNER)/$(GH_REPO_MODULES).git//modules
MODULES_TAG	  	:= ?ref=$(GH_REPO_MODULES_REF)



# ==========================
# Terraform Backend Repository Configuration

backend-common-config := \
	-backend-config="resource_group_name=$(TFSTATE_RG_NAME)" \
	-backend-config="storage_account_name=$(TFSTATE_STORAGE_ACCOUNT_NAME)" \
	-backend-config="container_name=$(TFSTATE_CONTAINER_NAME)"

backend-config-bootstrap 	:= $(backend-common-config) -backend-config="key=$(TFSTATE_KEY)"
backend-config-platform 	:= $(backend-common-config) -backend-config="key=$(PLATFORM_TFSTATE_KEY)"
backend-config-databricks 	:= $(backend-common-config) -backend-config="key=$(DATABRICKS_TFSTATE_KEY)"
backend-config-azureml 		:= $(backend-common-config) -backend-config="key=$(AZUREML_TFSTATE_KEY)"

# keys:
# 	echo "Terraform state key: $(DATABRICKS_TFSTATE_KEY)"

# ==========================
# OIDC configuration for Terraform and GitHub Actions integration

TF_OIDC_SUBJECT				:= repo:$(GH_OWNER)/$(GH_REPO_LIVE):ref:refs/heads/$(GH_REPO_LIVE_BRANCH)
TF_OIDC_SUBJECT_DATABRICKS	:= repo:$(GH_OWNER)/$(GH_REPO_DATABRICKS):ref:refs/heads/$(GH_REPO_DATABRICKS_BRANCH)
TF_OIDC_SUBJECT_AZUREML		:= repo:$(GH_OWNER)/$(GH_REPO_AZUREML):ref:refs/heads/$(GH_REPO_AZUREML_BRANCH)