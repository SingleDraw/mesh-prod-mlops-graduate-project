
# ----------------------
# A. Test Databricks CLI connectivity and authentication Locally
# ----------------------
# pip install databricks-cli

get-dbx-creds:
	@DBX_URL="$$(./scripts/azure/get-output-value.sh \
		DATABRICKS_TFSTATE_KEY \
		databricks_url)" && \
	export DATABRICKS_HOST="https://$$DBX_URL" && \
	export DATABRICKS_TOKEN="$$(az account get-access-token \
	--resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d \
	--query accessToken -o tsv)" && \
	echo "DATABRICKS_HOST=$$DATABRICKS_HOST" && \
	echo "DATABRICKS_TOKEN=$$DATABRICKS_TOKEN" && \
	databricks workspace list / && \
	databricks clusters list
# databricks clusters list

# -----------------------
# B. Test Databricks CLI connectivity and authentication in CI (GitHub Actions)
# -----------------------
trigger-upload-xlsx-workflow:
	gh workflow run "upload-xlsx.yml" --repo "$(DATABRICKS_REPO)" --ref main

trigger-dbx-cd-workflow: 	# deploy bundle and run pipeline
	gh workflow run "pipeline-cd.yml" --repo "$(DATABRICKS_REPO)" --ref main

# =========================================================
# Databricks Terraform Deployment Targets (locally) - DO NOT SPIN DBX LOCALLY, ONLY VIA CI WORKFLOWS
# --------------------------

local-dbx-path:=$(DATABRICKS_INFRA)

define dbx-env-exports
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID); \
	export TF_VAR_resource_group_name=$(RESOURCE_GROUP_NAME); \
	export TF_VAR_location=$(LOCATION); \
	export TF_VAR_storage_account_name=$(STORAGE_ACCOUNT_NAME); \
	export TF_VAR_key_vault_name=$(KEY_VAULT_NAME); \
	export TF_VAR_workspace_name=$(WORKSPACE_NAME); \
	export TF_VAR_acr_name=$(ACR_NAME); \
	export TF_VAR_application_insights_name=$(APPLICATION_INSIGHTS_NAME); \
	export TF_VAR_endpoint_name=$(ENDPOINT_NAME); \
	export TF_VAR_datalake_resource_group_name=$(PLATFORM_RESOURCE_GROUP_NAME); \
	export TF_VAR_datalake_storage_account_name=$(DATALAKE_NAME); \
	export ARM_USE_AZUREAD=true; \
	export ARM_SUBSCRIPTION_ID=$(SUBSCRIPTION_ID);
endef
# TF_VAR_sa_uami_name: ${{ vars.SA_UAMI_NAME }}

# dont use! only for testing and if you know what you are doing.
tf-databricks-apply:
	$(call dbx-env-exports) \
	terraform -chdir=$(local-dbx-path) \
			init --upgrade $(backend-config-databricks) && \
	terraform -chdir=$(local-dbx-path) \
			apply -auto-approve;

# cleanup above! in prod use CI/CD workflows to provision DBX
tf-databricks-destroy:
	$(call dbx-env-exports) \
	terraform -chdir=$(local-dbx-path) \
			init --upgrade $(backend-config-databricks) && \
	terraform -chdir=$(local-dbx-path) \
			destroy -auto-approve;

# -- remote triggers to apply/destroy Databricks infra via GitHub Actions (CI) ---
# make generate-live-repo
# make trigger-live-workload-dbx-ci

# make generate-databricks-repo

# make trigger-destroy-workload-azureml-ci

# ---------------------------------------
# If state stucks get its lock ID from error message 
# and run below command to unlock
# ---------------------------------------

LOCK_ID	:=	54908c89-46b3-e528-c733-12b619faa7a4

unlock-tf-databricks:
	yes | terraform -chdir=$(local-dbx-path) \
			force-unlock $(LOCK_ID)