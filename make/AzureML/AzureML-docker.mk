

# =========================================================
# Build and test Docker Images with AzureML base images
# before delpoying to AzureML,
# make sure that our Dockerfile builds correctly 
# and that the environment works as expected. (saves time and resources!)
# ==========================================================

DOCKER_DIR 		:= templates/azureml/docker
TEMPLATE_DIR 	:= templates


build-env-image:
	sed -i 's/\r$$//' $(DOCKER_DIR)/Dockerfile.delta && \
	cp $(DOCKER_DIR)/Dockerfile.delta $(LOCAL_REPOS)/azureml/docker/Dockerfile.delta && \
	docker build \
		--build-arg ENV_FILE_PATH=test-delta-env.yml \
		-t azure-sim:latest \
		-f $(LOCAL_REPOS)/azureml/docker/Dockerfile.delta \
		$(TEMPLATE_DIR)/azureml/ --no-cache && \
	docker inspect azure-sim:latest --format='{{.Size}}' | numfmt --to=iec

test-delta-env-image:
	docker run -it --rm \
		-v ${PWD}/tests/:/home/sim/tests/ \
		azure-sim:latest bash -c "cd /home/sim/tests/ && python test_delta.py"
test-delta-env-image-interactive:
	docker run -it --rm \
		-v ${PWD}/tests/:/home/sim/tests/ \
		azure-sim:latest \
		conda run -n ml bash -c "cd /home/sim/tests/ && python test_delta.py"
test-delta-env-image-basic:
	docker run --rm azure-sim:latest python -c "import mltable; print('ok')"

# -------------------------------------------------
# debugging tips:
# docker run --rm azure-sim:latest cat /tmp/env.yml 	# check if env file is in the image and has correct content
# docker run --rm azure-sim:latest conda env list 		# Valid result: ml environment should be listed. If not, ENV PATH did not work.
# docker run --rm azure-sim:latest which python 		# Valid result: /opt/miniconda/envs/ml/bin/python. If its: /opt/miniconda/bin/python - ENV PATH did not work.
