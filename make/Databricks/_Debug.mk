check-available-vm-skus:
	az vm list-skus \
		--location $(LOCATION) \
		--size Standard_D \
		--query "[?restrictions[?reasonCode=='NotAvailableForSubscription'] == \`[]\`].name" \
		--output table && \
	az vm list-skus \
		--location northeurope \
		--size Standard_E \
		--query "[?restrictions[?reasonCode=='NotAvailableForSubscription'] == \`[]\`].name" \
		--output table

# =========================================================
# Run Jobs

DATABRICKS_AZURE_ID:=2ff814a6-3304-4ab8-85cb-cd0e6f879c1d

run-db-job:
	@$(call unix-endings) && \
	cd $(DATABRICKS_INFRA) && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
	export TF_VAR_prefix=$(DATASTACK_PREFIX) && \
	export TF_VAR_location=$(LOCATION) && \
	WORKSPACE_URL="https://$$(terraform output -raw databricks_url)" && \
	JOB_ID=$$(terraform output -raw job_id) && \
	echo "Databricks workspace URL: $$WORKSPACE_URL" && \
	TOKEN=$$(az account get-access-token \
		--resource $(DATABRICKS_AZURE_ID) \
		--query accessToken -o tsv) && \
	echo "Running job to test connectivity..." && \
	curl -X POST \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		-d "{\"job_id\": $$JOB_ID}" \
		$$WORKSPACE_URL/api/2.0/jobs/run-now

check-db-job:
	@$(call unix-endings) && \
	cd $(DATABRICKS_INFRA) && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
	export TF_VAR_prefix=$(DATASTACK_PREFIX) && \
	export TF_VAR_location=$(LOCATION) && \
	JOB_ID=$$(terraform output -raw job_id) && \
	echo "Checking job run status for job ID: $$JOB_ID" && \
	WORKSPACE_URL="https://$$(terraform output -raw databricks_url)" && \
	TOKEN=$$(az account get-access-token \
		--resource $(DATABRICKS_AZURE_ID) \
		--query accessToken -o tsv) && \
	curl -X GET \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		$$WORKSPACE_URL/api/2.0/jobs/runs/list?job_id=$$JOB_ID 


RUN_ID=342409219600509

get-logs: # get run_id
	@$(call unix-endings) && \
	cd $(DATABRICKS_INFRA) && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
	export TF_VAR_prefix=$(DATASTACK_PREFIX) && \
	export TF_VAR_location=$(LOCATION) && \
	JOB_ID=$$(terraform output -raw job_id) && \
	echo "Getting logs for job ID: $$JOB_ID" && \
	WORKSPACE_URL="https://$$(terraform output -raw databricks_url)" && \
	TOKEN=$$(az account get-access-token \
		--resource $(DATABRICKS_AZURE_ID) \
		--query accessToken -o tsv) && \
	curl -s -X GET \
		-H "Authorization: Bearer $$TOKEN" \
		"$$WORKSPACE_URL/api/2.1/jobs/runs/get?run_id=$(RUN_ID)" \
		| python3 -m json.tool


TASKS_RUN_ID=697489011638976

get-logs-runid:
	@$(call unix-endings) && \
	cd $(DATABRICKS_INFRA) && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
	export TF_VAR_prefix=$(DATASTACK_PREFIX) && \
	export TF_VAR_location=$(LOCATION) && \
	JOB_ID=$$(terraform output -raw job_id) && \
	echo "Getting logs for job ID: $$JOB_ID" && \
	WORKSPACE_URL="https://$$(terraform output -raw databricks_url)" && \
	TOKEN=$$(az account get-access-token \
		--resource $(DATABRICKS_AZURE_ID) \
		--query accessToken -o tsv) && \
	curl -s -X GET \
		-H "Authorization: Bearer $$TOKEN" \
		"$$WORKSPACE_URL/api/2.1/jobs/runs/get-output?run_id=$(TASKS_RUN_ID)" \
		| python3 -c "import sys,json; r=json.load(sys.stdin); print(r.get('error','no error')); print(r.get('error_trace','no trace'))"



# =========================================================
# DELETE AZUREML WORKSPACE
# =========================================================
purge-azureml-workspace:
	az ml workspace delete \
		--name ml-workspace-prod \
		--resource-group rg-ml-prod \
		--permanently-delete \
		--yes



# =========================================================
# DEBUGGING TARGETS
# =========================================================
# If app insights already exists due to previous apply, 
# import it to avoid errors on subsequent applies
import-application-insights:
	$(call unix-endings) && \
	cd $(AZUREML_INFRA) && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
	export TF_VAR_resource_group_name=$(RESOURCE_GROUP_NAME) && \
	export TF_VAR_location=$(LOCATION) && \
	export TF_VAR_acr_name=$(ACR_NAME) && \
	export TF_VAR_storage_account_name=$(STORAGE_ACCOUNT_NAME) && \
	export TF_VAR_key_vault_name=$(KEY_VAULT_NAME) && \
	export TF_VAR_workspace_name=$(WORKSPACE_NAME) && \
	export TF_VAR_application_insights_name=$(APPLICATION_INSIGHTS_NAME) && \
	terraform import azurerm_application_insights.ai \
  	/subscriptions/$(SUBSCRIPTION_ID)/resourceGroups/$(RESOURCE_GROUP_NAME)/providers/Microsoft.Insights/components/$(APPLICATION_INSIGHTS_NAME)

import-role-assignment:
	$(call unix-endings) && \
	cd $(AZUREML_INFRA) && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
	export TF_VAR_resource_group_name=$(RESOURCE_GROUP_NAME) && \
	export TF_VAR_location=$(LOCATION) && \
	export TF_VAR_acr_name=$(ACR_NAME) && \
	export TF_VAR_storage_account_name=$(STORAGE_ACCOUNT_NAME) && \
	export TF_VAR_key_vault_name=$(KEY_VAULT_NAME) && \
	export TF_VAR_workspace_name=$(WORKSPACE_NAME) && \
	export TF_VAR_application_insights_name=$(APPLICATION_INSIGHTS_NAME) && \
terraform import azurerm_role_assignment.mlws_sa \
  /subscriptions/$(SUBSCRIPTION_ID)/resourceGroups/$(RESOURCE_GROUP_NAME)/providers/Microsoft.Storage/storageAccounts/$(STORAGE_ACCOUNT_NAME)/providers/Microsoft.Authorization/roleAssignments/5382a8004ecd41f2b632a195cb245d28

import:
	$(call unix-endings) && \
	cd $(AZUREML_INFRA) && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID) && \
	export TF_VAR_resource_group_name=$(RESOURCE_GROUP_NAME) && \
	export TF_VAR_location=$(LOCATION) && \
	export TF_VAR_acr_name=$(ACR_NAME) && \
	export TF_VAR_storage_account_name=$(STORAGE_ACCOUNT_NAME) && \
	export TF_VAR_key_vault_name=$(KEY_VAULT_NAME) && \
	export TF_VAR_workspace_name=$(WORKSPACE_NAME) && \
	export TF_VAR_application_insights_name=$(APPLICATION_INSIGHTS_NAME) && \
terraform import azurerm_role_assignment.mlws_sa \
  /subscriptions/$(SUBSCRIPTION_ID)/resourceGroups/$(RESOURCE_GROUP_NAME)/providers/Microsoft.Storage/storageAccounts/$(STORAGE_ACCOUNT_NAME)/providers/Microsoft.Authorization/roleAssignments/5382a8004ecd41f2b632a195cb245d28
