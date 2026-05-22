
databricks-template-repo := databricks

# rr: 
# 	sed -i 's/\r$$//' ./secrets/.datalake_sp_creds.env && \
# 	export $$(cat ./secrets/.datalake_sp_creds.env | xargs) && \
# 	echo "DATALAKE_SP_CLIENT_ID=$$DATALAKE_CLIENT_ID" && \
# 	echo "DATALAKE_SP_CLIENT_SECRET=$$DATALAKE_CLIENT_SECRET" && \
# 	echo "DATALAKE_SP_TENANT_ID=$$DATALAKE_TENANT_ID"

inject-databricks-vars:
	@./scripts/repo/inject-vars.sh $(LOCAL_REPOS)/$(databricks-template-repo) "*" \
		"{{TEAM}}" "$(TEAM)" \
		"{{STAGE}}" "$(STAGE)" \
		"{{ENVIRONMENT}}" "$(ENVIRONMENT)" \
		"{{CONTAINER_NAME}}" "$(CONTAINER_NAME)" \
		"{{STORAGE_ACCOUNT_NAME}}" "$(DATALAKE_NAME)" \
		"{{SHARED_DATASTORE_NAME}}" "$(SHARED_DATASTORE_NAME)" \
		"{{DELTA_MLTABLE_DIR}}" "$(DELTA_MLTABLE_DIR)" \
		"{{DELTA_TABLE_RELATIVE}}" "$(DELTA_TABLE_RELATIVE)" && \
	UAMI_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		uami_client_id)" && \
	SP_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_id)" && \
	SP_CLIENT_SECRET="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_secret)" && \
	DATABRICKS_HOST="https://$$(./scripts/azure/get-output-value.sh \
		DATABRICKS_TFSTATE_KEY \
		databricks_url)" && \
	./scripts/repo/inject-vars.sh $(LOCAL_REPOS)/$(databricks-template-repo) "*" \
		"{{UAMI_CLIENT_ID}}" "$$UAMI_CLIENT_ID" \
		"{{UAMI_TENANT_ID}}" "$(TENANT_ID)" \
		"{{SP_CLIENT_ID}}" "$$SP_CLIENT_ID" \
		"{{SP_TENANT_ID}}" "$(TENANT_ID)" \
		"{{SP_CLIENT_SECRET}}" "$$SP_CLIENT_SECRET" \
		"{{DATABRICKS_HOST}}" "$$DATABRICKS_HOST"

# ===========================
# Init Databricks repo from template (locally)
# ===========================
init-databricks-repo:
	@$(call init-repo-from-template,$(databricks-template-repo))
	@$(MAKE) inject-databricks-vars

create-databricks-repo:
	$(call create-repo,$(databricks-template-repo),$(GH_REPO_DATABRICKS))

testi:
	echo $(SUBSCRIPTION_ID)

# shared secrets and varables for all live workloads (platform, databricks, azure ml)
set-databricks-secrets:
	@export DBX_URL="$$(./scripts/azure/get-output-value.sh \
		DATABRICKS_TFSTATE_KEY \
		databricks_url)" && \
	export SP_CLIENT_SECRET="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_secret)" && \
	echo "DATABRICKS_HOST=https://$${DBX_URL}" && \
	REPO=$(DATABRICKS_REPO) \
	DATABRICKS_HOST="https://$${DBX_URL}" \
	SP_CLIENT_SECRET="$${SP_CLIENT_SECRET}" \
	SECRET=true \
	./scripts/gh/set-variable.sh \
		"DATABRICKS_HOST" "https://$${DBX_URL}" \
		"SUBSCRIPTION_ID" "$(SUBSCRIPTION_ID)" && \
	REPO=$(DATABRICKS_REPO) SECRET=false ./scripts/gh/set-variable.sh \
		"DATABRICKS_RESOURCE_GROUP" "$(RESOURCE_GROUP_NAME)" \
		"DATABRICKS_WORKSPACE_NAME" "$(WORKSPACE_NAME)" \
		"DATALAKE_NAME" "$(DATALAKE_NAME)"

set-databricks-secrets-ci: # SP CLIENT_SECRET ID AND TENANT_ID
	@REPO=$(DATABRICKS_REPO) SECRET=true ./scripts/gh/set-variable.sh \
		"DATABRICKS_CLIENT_SECRET" "$$(./scripts/azure/get-output-value.sh \
			PLATFORM_TFSTATE_KEY \
			databricks_sp_client_secret)" \
		"DATABRICKS_CLIENT_ID" "$$(./scripts/azure/get-output-value.sh \
			PLATFORM_TFSTATE_KEY \
			databricks_sp_client_id)" \
		"DATABRICKS_TENANT_ID" "$(TENANT_ID)"

# loads bootstrap SP that doesnt have access to Data Lake
load-databricks-client-creds:
	@./scripts/gh/set-client-creds.sh \
		"$$(./scripts/azure/get-output-value.sh TFSTATE_KEY terraform_sp_client_id)" \
 		"$(DATABRICKS_REPO)"

push-databricks-repo:
	$(call force-push-repo,$(databricks-template-repo),$(GH_REPO_DATABRICKS))

# =========================================================
# High-level target to generate Databricks repository with all configurations
# --------------------------
generate-databricks-repo:
	@$(MAKE) init-databricks-repo
	@$(MAKE) create-databricks-repo
	@$(MAKE) load-databricks-client-creds
	@$(MAKE) set-databricks-secrets
	@$(MAKE) set-databricks-secrets-ci
	@$(MAKE) push-databricks-repo


# runned from local PC:
debug-databricks-admins:
	@DBX_URL="https://$$(./scripts/azure/get-output-value.sh \
		DATABRICKS_TFSTATE_KEY \
		databricks_url)" && \
	TOKEN="$$(az account get-access-token \
		--resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d \
		--query accessToken -o tsv)" && \
	curl -s -H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		"$$DBX_URL/api/2.0/preview/scim/v2/ServicePrincipals"


check-databricks-admins:
	@SP_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		TFSTATE_KEY \
		terraform_sp_client_id)" && \
	TOKEN="$$(az account get-access-token \
		--resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d \
		--query accessToken -o tsv)" && \
	echo "Adding SP $${SP_CLIENT_ID} to Databricks workspace admins..."
	