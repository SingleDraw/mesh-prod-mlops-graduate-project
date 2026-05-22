
azureml_secret_path := "templates/azureml/.datalake_sp_creds.env"

store-datalake-client-creds-azureml:
	@SP_CLIENT_SECRET="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_secret)" && \
	SP_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_id)" && \
	echo "DATALAKE_ACCOUNT_NAME=$(DATALAKE_NAME)" > $(azureml_secret_path) && \
	echo "DATALAKE_TENANT_ID=$(TENANT_ID)" >> $(azureml_secret_path) && \
	echo "DATALAKE_CLIENT_ID=$$SP_CLIENT_ID" >> $(azureml_secret_path) && \
	echo "DATALAKE_CLIENT_SECRET=$$SP_CLIENT_SECRET" >> $(azureml_secret_path) && \
	sed -i 's/\r$//' $(azureml_secret_path)