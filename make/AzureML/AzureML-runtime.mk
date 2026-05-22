
azml_repo := --repo $(AZUREML_REPO) --ref $(GH_REPO_AZUREML_BRANCH)
azml_load := -g $(RESOURCE_GROUP_NAME) -w $(WORKSPACE_NAME)

# make generate-azureml-repo

## CI/CD runtime Substitutions for secrets and versions:
#  __COMP_VERSION__  <- pipeline, component
#  __ENV_VERSION__   <- environment, component
#  __INSTANCE_TYPE__ <- component, pipeline
#  __DATA_VERSION__  <- dataset, pipeline
#  __CLIENT_SECRET__ <- datastore

# ==========================
# Test AzureML OIDC Authentication with SDK
# ==========================
trigger-azureml-workflow-test-auth:
	gh workflow run "AzureML OIDC Auth Test" $(azml_repo)


# ==========================
# Create URI folder in Shared Storage 
# for AzureML Datastore and upload test file
# ==========================
create-test-datastore-dataset:
	az storage fs directory create \
		--name test \
		--file-system $(CONTAINER_NAME) \
		--account-name $(STORAGE_ACCOUNT_NAME) \
		--auth-mode key && \
	echo "hello datastore" > test.txt && \
	az storage fs file upload \
		--source test.txt \
		--path test/test.txt \
		--file-system $(CONTAINER_NAME) \
		--account-name $(STORAGE_ACCOUNT_NAME) \
		--auth-mode key && \
	rm test.txt


# make generate-azureml-repo
# trigger-azureml-workflow-delta-resource-registration

# Run Workflow: DATALAKE REGISTRATION (datastore pointing to shared storage) [v]
# ==========================
trigger-azureml-workflow-datalake-registration: # independent step
	gh workflow run ci-register-datalake.yml $(azml_repo)

trigger-azureml-workflow-upload-mltable:		# independent step (storage should be provisioned and accessible)
	gh workflow run ci-upload-mltable.yml $(azml_repo)

# # Run Workflow: PIPELINE TEST [v]
# # ==========================
# trigger-azureml-workflow-resource-registration:
# 	gh workflow run ci-register-resources.yml $(azml_repo)
# trigger-azureml-workflow-pipeline-test:
# 	gh workflow run cd-submit-test-pipeline.yml $(azml_repo)

# Run Workflow: PIPELINE TEST with Delta Lake dataset [v]
# ==========================
trigger-azureml-workflow-delta-resource-registration: 	# if success deploys pipeline automatically
	gh workflow run ci-register-delta-resources.yml $(azml_repo)
trigger-azureml-workflow-submit-delta-pipeline:
	gh workflow run cd-submit-delta-pipeline.yml $(azml_repo)


# # Simulate docker builds for jobs:
# # DOCKER_DIR := $(LOCAL_REPOS)/azureml/docker
# DOCKER_DIR := templates/azureml/docker
# build-delta-env-image:
# 	sed -i 's/\r$$//' $(DOCKER_DIR)/Dockerfile.delta && \
# 	cp $(DOCKER_DIR)/Dockerfile.delta $(LOCAL_REPOS)/azureml/docker/Dockerfile.delta && \
# 	docker build -t azure-sim:latest \
# 	-f $(LOCAL_REPOS)/azureml/docker/Dockerfile.delta \
# 	$(LOCAL_REPOS)/azureml/ \
# 	--no-cache && \
# 	docker inspect azure-sim:latest --format='{{.Size}}' | numfmt --to=iec

# test-delta-env-image:
# 	docker run -it --rm azure-sim:latest bash




# ==========================
# Delete datastore! [DEV]
# ==========================
delete-test-datastore-dataset:
	yes | az ml datastore delete --name $(SHARED_DATASTORE_NAME) $(azml_load) || true


# ---------------------------
# debug
show-azureml-environment:
	az ml environment show --name test-env --version d8dd88df $(azml_load)


