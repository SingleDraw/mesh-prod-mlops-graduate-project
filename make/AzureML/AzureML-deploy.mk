
azureml-template-repo := azureml

# ---------------------------------
# Tags
TEAM 							:= ml-platform
ENVIRONMENT 					:= production
STAGE							:= staging  	# used in model.yml

# ---------------------------------
# ADLS and Feature Store configuration
CONTAINER_NAME 					:= raw

# MLTable and Delta Lake configuration
DELTA_MLTABLE_DIR				:= delta/gold
DELTA_TABLE_RELATIVE			:= production_time
DELTA_TABLE_PATH                := $(DELTA_MLTABLE_DIR)/$(DELTA_TABLE_RELATIVE)

# only lowercase and underscores allowed in datastore names
SHARED_DATASTORE_NAME 			:= shared_adls

# for deploying model.yml - not used yet
FEATURE_STORE_DATASET_NAME 		:= prod_time_features
FEATURE_STORE_DATASET_VERSION 	:= 1

# ----------------------------------
# AzureML configuration
# instance type for all AML compute resources (training, inference) - can be overridden in component.yml
INSTANCE_TYPE 					:= Standard_DS2_v2
# name must be unique within region, as it's part of the endpoint's URL: https://<region>.azurewebsites.net/endpoints/<endpoint_name>/
ENDPOINT_NAME 					:= $(ENDPOINT_NAME)
# vars for model deployment
MODEL_NAME 						:= production_time_model
MODEL_VERSION 					:= 1
# vars for pipeline
TRAINING_PIPELINE_NAME 			:= production_time_training_pipeline

# ----------------------------------
# environment variables configuration
TRAIN_ENV_VERSION 				:= 1
INFERENCE_ENV_VERSION 			:= 1
TEST_ENV_VERSION 				:= 1

# --------------------------
# Helpers
# --------------------------
get-uami-client-id:
	UAMI_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		uami_client_id)" && \
	echo "$$UAMI_CLIENT_ID"

get-sp-client-id:
	SP_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_id)" && \
	echo "$$SP_CLIENT_ID"

get-sp-client-secret:
	SP_CLIENT_SECRET="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_secret)" && \
	echo "$$SP_CLIENT_SECRET"

# Inject variables into AzureML repo template
inject-azureml-vars:
	@./scripts/repo/inject-vars.sh $(LOCAL_REPOS)/$(azureml-template-repo) "*" \
		"{{TEAM}}" "$(TEAM)" \
		"{{STAGE}}" "$(STAGE)" \
		"{{ENVIRONMENT}}" "$(ENVIRONMENT)" \
		"{{CONTAINER_NAME}}" "$(CONTAINER_NAME)" \
		"{{STORAGE_ACCOUNT_NAME}}" "$(DATALAKE_NAME)" \
		"{{SHARED_DATASTORE_NAME}}" "$(SHARED_DATASTORE_NAME)" \
		"{{DELTA_MLTABLE_DIR}}" "$(DELTA_MLTABLE_DIR)" \
		"{{DELTA_TABLE_RELATIVE}}" "$(DELTA_TABLE_RELATIVE)" \
		"{{FEATURE_STORE_DATASET_NAME}}" "$(FEATURE_STORE_DATASET_NAME)" \
		"{{FEATURE_STORE_DATASET_VERSION}}" "$(FEATURE_STORE_DATASET_VERSION)" \
		"{{INSTANCE_TYPE}}" "$(INSTANCE_TYPE)" \
		"{{ENDPOINT_NAME}}" "$(ENDPOINT_NAME)" \
		"{{MODEL_NAME}}" "$(MODEL_NAME)" \
		"{{MODEL_VERSION}}" "$(MODEL_VERSION)" \
		"{{TRAINING_PIPELINE_NAME}}" "$(TRAINING_PIPELINE_NAME)" \
		"{{TRAIN_ENV_VERSION}}" "$(TRAIN_ENV_VERSION)" \
		"{{INFERENCE_ENV_VERSION}}" "$(INFERENCE_ENV_VERSION)" && \
	UAMI_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		uami_client_id)" && \
	SP_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_id)" && \
	SP_CLIENT_SECRET="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_secret)" && \
	./scripts/repo/inject-vars.sh $(LOCAL_REPOS)/$(azureml-template-repo) "*" \
		"{{UAMI_CLIENT_ID}}" "$$UAMI_CLIENT_ID" \
		"{{UAMI_TENANT_ID}}" "$(TENANT_ID)" \
		"{{SP_CLIENT_ID}}" "$$SP_CLIENT_ID" \
		"{{SP_TENANT_ID}}" "$(TENANT_ID)" \
		"{{SP_CLIENT_SECRET}}" "$$SP_CLIENT_SECRET"


# ===========================
# Init AzureML repo from template (locally)
# ===========================
init-azureml-repo:
	@$(call init-repo-from-template,$(azureml-template-repo))
	@$(MAKE) inject-azureml-vars

create-azureml-repo:
	$(call create-repo,$(azureml-template-repo),$(GH_REPO_AZUREML))

# shared secrets and varables for all live workloads (platform, databricks, azure ml)
set-azureml-secrets:
	@export SP_CLIENT_SECRET="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_secret)" && \
	REPO=$(AZUREML_REPO) SECRET=true SP_CLIENT_SECRET="$${SP_CLIENT_SECRET}" \
	./scripts/gh/set-variable.sh \
		"SUBSCRIPTION_ID" "$(SUBSCRIPTION_ID)" && \
	REPO=$(AZUREML_REPO) SECRET=false ./scripts/gh/set-variable.sh \
		"AML_RESOURCE_GROUP" "$(RESOURCE_GROUP_NAME)" \
		"AML_WORKSPACE_NAME" "$(WORKSPACE_NAME)" 

load-azureml-client-creds:
	@./scripts/gh/set-client-creds.sh \
		"$$(./scripts/azure/get-output-value.sh TFSTATE_KEY terraform_sp_client_id)" \
 		"$(AZUREML_REPO)"

push-azureml-repo:
	$(call force-push-repo,$(azureml-template-repo),$(GH_REPO_AZUREML))

# =========================================================
# High-level target to generate AzureML repository with all configurations
# --------------------------
generate-azureml-repo:
	@$(MAKE) init-azureml-repo
	@$(MAKE) create-azureml-repo
	@$(MAKE) load-azureml-client-creds
	@$(MAKE) set-azureml-secrets
	@$(MAKE) push-azureml-repo


# ==========================
# Test targets (locally)
# ==========================
deploy-endpoint:
	@echo "Deploying model to endpoint..." && \
	cd $(LOCAL_REPOS)/$(azureml-template-repo) && \
	(\
	az ml online-endpoint create \
		--file deploy/endpoints/online/endpoint.yml \
		--resource-group $(RESOURCE_GROUP_NAME) \
		--workspace-name $(WORKSPACE_NAME) || \
	az ml online-endpoint update \
		--file deploy/endpoints/online/endpoint.yml \
		--resource-group $(RESOURCE_GROUP_NAME) \
		--workspace-name $(WORKSPACE_NAME) \
	)
