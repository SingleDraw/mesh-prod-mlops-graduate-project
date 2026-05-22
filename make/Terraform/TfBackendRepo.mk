
boot-template-repo	:= tf-backend
boot-path 			:= $(LOCAL_REPOS)/$(boot-template-repo)

# ==========================
# Terraform Backend Bootstrap Repository
# ==========================
inject-bootstrap-vars:
	@./scripts/repo/inject-vars.sh $(boot-path) tf \
		"{{MODULES_URL}}" "$(MODULES_URL)" \
		"{{?MODULES_TAG}}" "$(MODULES_TAG)"
	@./scripts/repo/inject-vars.sh $(boot-path) tfvars \
		"{{PROJECT_NAME}}" "$(PROJECT_NAME)" \
		"{{OWNER}}" "$(OWNER)" \
		"{{DEPLOYED_BY}}" "$(DEPLOYED_BY)" \
		"{{OIDC_SUBJECT}}" "$(TF_OIDC_SUBJECT)" \
		"{{OIDC_SUBJECT_DATABRICKS}}" "$(TF_OIDC_SUBJECT_DATABRICKS)" \
		"{{OIDC_SUBJECT_AZUREML}}" "$(TF_OIDC_SUBJECT_AZUREML)"

create-backend-deploy-key:
	@$(call create-local-deploy-key,backend-repo-deploy-key,backend_deploy_key,$(MODULES_REPO))

init-bootstrap:
	@$(call init-repo-from-template,$(boot-template-repo))
	@$(MAKE) inject-bootstrap-vars

tf-push-state:
	@./scripts/bootstrap/tf-push-state.sh \
		$(boot-path) \
		$(SUBSCRIPTION_ID) \
		$(TFSTATE_RG_NAME) \
		$(TFSTATE_STORAGE_ACCOUNT_NAME) \
		$(TFSTATE_CONTAINER_NAME) \
		$(TFSTATE_KEY)


tf-bootstrap-apply:
	@RESULT=$$(ARM_SUBSCRIPTION_ID=$(SUBSCRIPTION_ID) \
	./scripts/terraform/check-tfstate.sh \
		$(TFSTATE_STORAGE_ACCOUNT_NAME) \
		$(TFSTATE_CONTAINER_NAME) \
		$(TFSTATE_KEY) \
	) && \
	export GIT_SSH_COMMAND="ssh -i ./secrets/.ssh/backend_repo_deploy_key -o IdentitiesOnly=yes" && \
	export TF_VAR_subscription_id=$(SUBSCRIPTION_ID); \
	export TF_VAR_resource_group_name=$(TFSTATE_RG_NAME); \
	export TF_VAR_location=$(LOCATION); \
	export TF_VAR_storage_account_name=$(TFSTATE_STORAGE_ACCOUNT_NAME); \
	if [ "$$RESULT" = "local" ]; then \
		echo "Using local state..." && \
		$(boot-path)/toggle-backend.sh "disable" "$(boot-path)" && \
		terraform -chdir=$(boot-path) init --upgrade && \
		terraform -chdir=$(boot-path) apply -auto-approve; \
		$(MAKE) tf-push-state; \
	else \
		echo "Using remote state..." && $(boot-path)/toggle-backend.sh "enable" "$(boot-path)" && \
		export ARM_USE_AZUREAD=true && \
		export ARM_SUBSCRIPTION_ID=$(SUBSCRIPTION_ID) && \
		terraform -chdir=$(boot-path) \
			init --upgrade $(backend-config-bootstrap) && \
		terraform -chdir=$(boot-path) apply -auto-approve; \
	fi

clean-local-state:
	@RESULT=$$(ARM_SUBSCRIPTION_ID=$(SUBSCRIPTION_ID) \
	./scripts/terraform/check-tfstate.sh \
		$(TFSTATE_STORAGE_ACCOUNT_NAME) \
		$(TFSTATE_CONTAINER_NAME) \
		$(TFSTATE_KEY) \
	) && \
	if [ "$$RESULT" = "remote" ]; then \
		echo "$(green)Successfully accessed remote state storage. State is now remote.$(reset)"; \
		rm -f $(boot-path)/local.tfstate; \
		rm -f $(boot-path)/terraform.tfstate; \
	else \
		echo "$(red)Failed to access remote state storage or file not found.$(reset)"; \
		echo "$(red)State may still be local.$(reset)"; \
		exit 1; \
	fi

# ==========================
# Main Target
# ==========================
generate-bootstrap:
	@$(MAKE) init-bootstrap && \
	$(MAKE) create-backend-deploy-key && \
	$(MAKE) tf-bootstrap-apply && \
	$(MAKE) clean-local-state





# --------------------------
# Debugging target to check backend configuration and state access
# test pulling state from remote backend
test-pull-state:
	@echo "Pulling latest Terraform state from remote backend..."
	@./scripts/utils/unix-endings.sh ".env"
	@set -a && source .env && set +a && \
	( \
		cd $(boot-path) && \
		export ARM_USE_AZUREAD=true && \
		export ARM_SUBSCRIPTION_ID=$(SUBSCRIPTION_ID) && \
		terraform init -upgrade -reconfigure $(backend-config-bootstrap) && \
		terraform state pull > local.tfstate \
	) && \
	if [ -f $(boot-path)/local.tfstate ]; then \
		echo "$(green)Successfully pulled state from remote backend. State is now local at $(boot-path)/local.tfstate$(reset)"; \
	else \
		echo "$(red)Failed to pull state from remote backend. Please check your configuration and access permissions.$(reset)"; \
		exit 1; \
	fi

check-blobs:
	@echo "Listing blobs in remote state storage..."
	@az storage blob list \
		--account-name $(TFSTATE_STORAGE_ACCOUNT_NAME) \
		--container-name $(TFSTATE_CONTAINER_NAME) \
		--output table \
		--auth-mode login
