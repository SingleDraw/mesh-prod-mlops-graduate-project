# ===================================
# Shared Storage Helper Functions
# ===================================
# Local targets for development and debugging
# -- jupyterlab and storage - delta saves to datalake gen2
# ===================================
# Store locally SP client secret
# - required to access datalake 
# 	from local notebooks
# ===================================
store-datalake-client-creds:
	@SP_CLIENT_SECRET="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_secret)" && \
	SP_CLIENT_ID="$$(./scripts/azure/get-output-value.sh \
		PLATFORM_TFSTATE_KEY \
		databricks_sp_client_id)" && \
	echo "DATALAKE_TENANT_ID=$(TENANT_ID)" > secrets/.datalake_sp_creds.env && \
	echo "DATALAKE_CLIENT_ID=$$SP_CLIENT_ID" >> secrets/.datalake_sp_creds.env && \
	echo "DATALAKE_CLIENT_SECRET=$$SP_CLIENT_SECRET" >> secrets/.datalake_sp_creds.env && \
	sed -i 's/\r$//' secrets/.datalake_sp_creds.env

docker-build-jupyterlab:
	docker build -t singledraw-jupyterlab:latest -f docker/Dockerfile.jupyterlab . && \
	docker inspect singledraw-jupyterlab:latest --format='{{.Size}}' | numfmt --to=iec

run-jupyterlab:
	docker compose -f docker/jupyter.yml up -d jupyter-lab
down-jupyterlab:
	docker compose -f docker/jupyter.yml down

# cp ~/notebooks/Delta.ipynb ./notebooks
# co ./notebooks/Delta.ipynb ~/notebooks

# test-jlab:
# 	docker run \
# 	--name "jupyter-lab" \
# 	-p 8888:8888 \
# 	-v ${PWD}/notebooks/:/home/spark/notebooks/ \
# 	--user "spark:spark" singledraw/jlab-spark:1.0.0 \
# 	jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.token=''




# -- get jlab notebooks to local notebooks folder
# cp ~/notebooks/MLTable_set.ipynb ./notebooks
# cp ~/notebooks/MLTable_template ./notebooks

# cp ./notebooks/MLTable_set.ipynb ~/notebooks
# cp ./notebooks/MLTable_template ~/notebooks







.PHONY: db_up

#---------------------
# Java
#---------------------
java_version:
	java -version

java_install_openjdk-17:
	sudo apt update
	sudo apt install openjdk-17-jdk

java_select:
	sudo update-alternatives --config java
	@echo "Selected Java version:"
	java -version

compatibility_test:
	export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 && \
	python -m scripts.spark.test

test_spark:
	python -m test_spark

#---------------------
# Explore Data
#---------------------
explore:
	export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 && \
	python -m explore

#---------------------
# Database
#---------------------
db_up:
	@docker info > /dev/null 2>&1 || { printf "\n  >>> Docker is not running. Please start Docker and try again.\n\n"; exit 1; }
	docker compose up -d db

db_down:
	docker compose down

# Sprawdź rozmiar wolumenu bazy danych. Powinno być ~5.3 GB
check_volume_size: 
	docker compose exec db du -sh /var/lib/postgresql/data

# Usuń bazę danych i wolumen danych, aby zacząć od nowa
db_downv:
	docker compose down -v

# verify database connection and tables
verify:
	@docker compose exec db psql -U postgres -c "\dt"
	@./config/verify.sh

# ---------------------
# Test Spark SQL with PostgreSQL JDBC
# ---------------------
spark:
	export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 && \
	python -m spark