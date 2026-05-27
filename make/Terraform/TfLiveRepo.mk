
live-template-repo 	:= tf-live
PLATFORM_INFRA 		:= $(LOCAL_REPOS)/$(live-template-repo)/platform
DATABRICKS_INFRA 	:= $(LOCAL_REPOS)/$(live-template-repo)/workloads/databricks
AZUREML_INFRA 		:= $(LOCAL_REPOS)/$(live-template-repo)/workloads/azure-ml

inject-live-vars:
	@./scripts/repo/inject-vars.sh $(LOCAL_REPOS)/$(live-template-repo) "*" \
		"{{MODULES_URL}}" "$(MODULES_URL)" \
		"{{?MODULES_TAG}}" "$(MODULES_TAG)" \
		"{{PROJECT_NAME}}" "$(PROJECT_NAME)" \
		"{{OWNER_NAME}}" "$(OWNER)"
# 		"{{ACR_NAME}}" "$(ACR_NAME)"

init-live-repo:
	$(call init-repo-from-template,$(live-template-repo))
	@$(MAKE) inject-live-vars

create-live-repo:
	$(call create-repo,$(live-template-repo),$(GH_REPO_LIVE))

# shared secrets and varables for all live workloads (platform, databricks, azure ml)
set-live-secrets:
	@REPO=$(LIVE_REPO) SECRET=true ./scripts/gh/set-variable.sh \
		"SUBSCRIPTION_ID" "$(SUBSCRIPTION_ID)" && \
	REPO=$(LIVE_REPO) SECRET=false ./scripts/gh/set-variable.sh \
		"BACKEND_RESOURCE_GROUP" "$(TFSTATE_RG_NAME)" \
		"BACKEND_STORAGE_ACCOUNT" "$(TFSTATE_STORAGE_ACCOUNT_NAME)" \
		"BACKEND_CONTAINER" "$(TFSTATE_CONTAINER_NAME)" \
			"BACKEND_KEY" "$(TFSTATE_KEY)" \
			"PLATFORM_STATE_KEY" "$(PLATFORM_TFSTATE_KEY)" \
			"DATABRICKS_STATE_KEY" "$(DATABRICKS_TFSTATE_KEY)" \
			"AZUREML_STATE_KEY" "$(AZUREML_TFSTATE_KEY)" \
		"RESOURCE_GROUP_NAME" "$(PLATFORM_RESOURCE_GROUP_NAME)" \
		"LOCATION" "$(PLATFORM_LOCATION)" \
		"STORAGE_ACCOUNT_NAME" "$(DATALAKE_NAME)" \
		"PREFIX" "$(DATASTACK_PREFIX)" \
		"SA_UAMI_NAME" "$(SA_UAMI_NAME)" \
		&& \
	echo "AzureML specific variables..." && \
	REPO=$(LIVE_REPO) SECRET=false ./scripts/gh/set-variable.sh \
		"AZUREML_RESOURCE_GROUP_NAME" "$(RESOURCE_GROUP_NAME)" \
		"AZUREML_LOCATION" "$(LOCATION)" \
		"AZUREML_STORAGE_ACCOUNT_NAME" "$(STORAGE_ACCOUNT_NAME)" \
		"ACR_NAME" "$(ACR_NAME)" \
		"KEY_VAULT_NAME" "$(KEY_VAULT_NAME)" \
		"WORKSPACE_NAME" "$(WORKSPACE_NAME)" \
		"ENDPOINT_NAME" "$(ENDPOINT_NAME)" \
		"APPLICATION_INSIGHTS_NAME" "$(APPLICATION_INSIGHTS_NAME)"


load-live-client-creds:
	@./scripts/gh/set-client-creds.sh \
		"$$(./scripts/azure/get-output-value.sh TFSTATE_KEY terraform_sp_client_id)" \
 		"$(LIVE_REPO)"

rotate-live-deploy-key:
	@$(call rotate-deploy-key,live-repo-deploy-key,live_deploy_key,$(MODULES_REPO),$(LIVE_REPO))

push-live-repo:
	$(call force-push-repo,$(live-template-repo),$(GH_REPO_LIVE))


# ----
get-shared-storage-id:
	STORAGE_ID="$$(./scripts/azure/get-output-value.sh PLATFORM_TFSTATE_KEY storage_account_id)" && \
	echo "$$STORAGE_ID"


# =========================================================
# High-level target to generate live repository 
# with all configurations
generate-live-repo: 
	@$(MAKE) init-live-repo
	@$(MAKE) create-live-repo
	@$(MAKE) load-live-client-creds
	@$(MAKE) set-live-secrets
	@$(MAKE) rotate-live-deploy-key
	@$(MAKE) push-live-repo



# =========================================================
# Infrastructure Targets
# These targets can be used to deploy or destroy 
# shared platform and workloads for Databricks and AzureML.
# =========================================================

# --- CI Workflows ---
trigger-live-platform-ci:
	@gh workflow run "TF Platform CI" --repo $(LIVE_REPO) --ref main
trigger-live-workload-dbx-ci:
	@gh workflow run "TF Databricks CI" --repo $(LIVE_REPO) --ref main
trigger-live-workload-azureml-ci:
	@gh workflow run "TF AzureML CI" --repo $(LIVE_REPO) --ref main

# --- Destroy Workflows ---
trigger-destroy-platform-ci:
	@gh workflow run "TF Platform Destroy" --repo $(LIVE_REPO) --ref main --field confirm="destroy"

trigger-destroy-workload-dbx-ci:
	@gh workflow run "TF Databricks Destroy" --repo $(LIVE_REPO) --ref main --field confirm="destroy"

trigger-destroy-workload-azureml-ci:
	@gh workflow run "TF AzureML Destroy" --repo $(LIVE_REPO) --ref main --field confirm="destroy"


# FIX DANGLING ASSIGNMENT
delete-dangling-assignment:
	ROLE_ID="8ad541f1fa0f4cd6b62ff39030422b54" && \
	az role assignment delete \
		--ids "/subscriptions/$(SUBSCRIPTION_ID)/resourceGroups/$(RESOURCE_GROUP_NAME)/providers/Microsoft.Storage/storageAccounts/$(STORAGE_ACCOUNT_NAME)/providers/Microsoft.Authorization/roleAssignments/$$ROLE_ID" && \
		echo "Deleted dangling role assignment with ID $$ROLE_ID" && \
	az role assignment list --all \
		--query "[?id=='/subscriptions/$(SUBSCRIPTION_ID)/providers/Microsoft.Authorization/roleAssignments/$$ROLE_ID']"

debug-assignments:
	az role assignment list \
	--scope /subscriptions/$(SUBSCRIPTION_ID)/resourceGroups/$(RESOURCE_GROUP_NAME)/providers/Microsoft.Storage/storageAccounts/$(STORAGE_ACCOUNT_NAME) \
	--query "[].{id:id, principalId:principalId, role:roleDefinitionName,  roleId:roleDefinitionId}" \
	-o table

# --- Platform Targets ---

# environment variables
define tf_platform
	$(call unix-endings) && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
	export TF_VAR_resource_group_name=$(PLATFORM_RESOURCE_GROUP_NAME) && \
	export TF_VAR_location=$(PLATFORM_LOCATION) && \
	export TF_VAR_storage_account_name=$(DATALAKE_NAME) && \
	export TF_VAR_sa_uami_name=$(SA_UAMI_NAME) && \
	export TF_VAR_prefix=$(DATASTACK_PREFIX)
endef

tf-platform-init:
	$(call tf_platform) && \
	terraform -chdir=$(PLATFORM_INFRA) init --reconfigure \
	--upgrade $(backend-config-platform)
tf-platform-apply:
	$(call tf_platform) && \
	terraform -chdir=$(PLATFORM_INFRA) apply -auto-approve
tf-platform-destroy:
	$(call tf_platform) && \
	terraform -chdir=$(PLATFORM_INFRA) destroy -auto-approve


# --- AzureML Targets ---
# # environment variables
# define tf_azureml
# 	$(call unix-endings) && \
# 	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
# 	export TF_VAR_resource_group_name=$(RESOURCE_GROUP_NAME) && \
# 	export TF_VAR_location=$(LOCATION) && \
# 	export TF_VAR_acr_name=$(ACR_NAME) && \
# 	export TF_VAR_storage_account_name=$(STORAGE_ACCOUNT_NAME) && \
# 	export TF_VAR_key_vault_name=$(KEY_VAULT_NAME) && \
# 	export TF_VAR_workspace_name=$(WORKSPACE_NAME) && \
# 	export TF_VAR_endpoint_name=$(ENDPOINT_NAME) && \
# 	export TF_VAR_application_insights_name=$(APPLICATION_INSIGHTS_NAME)
# endef
# tf-ml-init:
# 	$(call tf_azureml) && \
# 	terraform -chdir=$(AZUREML_INFRA) init --reconfigure \
# 	--upgrade $(backend-config-azureml)
# tf-ml-apply:
# 	$(call tf_azureml) && \
# 	terraform -chdir=$(AZUREML_INFRA) init --reconfigure \
# 	--upgrade $(backend-config-azureml) && \
# 	terraform -chdir=$(AZUREML_INFRA) apply -auto-approve
# tf-ml-destroy:
# 	$(call tf_azureml) && \
# 	terraform -chdir=$(AZUREML_INFRA) init --reconfigure \
# 	--upgrade $(backend-config-azureml) && \
# 	terraform -chdir=$(AZUREML_INFRA) destroy -auto-approve


# --- Databricks Targets ---

# # environment variables
# define tf_databricks
# 	$(call unix-endings) && \
# 	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
# 	export TF_VAR_prefix=$(DATASTACK_PREFIX) && \
# 	export TF_VAR_location=$(LOCATION) && \
# 	export TF_VAR_datalake_resource_group_name=$(PLATFORM_RESOURCE_GROUP_NAME) && \
# 	export TF_VAR_datalake_storage_account_name=$(DATALAKE_NAME)
# endef
# tf-dbx-init:
# 	$(call tf_databricks) && \
# 	terraform -chdir=$(DATABRICKS_INFRA) init --reconfigure \
# 	--upgrade $(backend-config-databricks)
# tf-dbx-apply:
# 	$(call tf_databricks) && \
# 	terraform -chdir=$(DATABRICKS_INFRA) apply -auto-approve
# tf-dbx-destroy:
# 	$(call tf_databricks) && \
# 	terraform -chdir=$(DATABRICKS_INFRA) destroy -auto-approve

tf-dbx-unlock-state:
	gh workflow run "TF Databricks State Unlock" \
		-f confirm=unlock \
		-f lock_id=$(DATABRICKS_LOCK_ID) \
		--repo $(LIVE_REPO) \
		--ref main

# --------------------------
# Debugging
debug-live-repo:
	@./scripts/gh/debug.sh $(LIVE_REPO)

delete-live-repo:
	gh repo delete $(LIVE_REPO) --yes
