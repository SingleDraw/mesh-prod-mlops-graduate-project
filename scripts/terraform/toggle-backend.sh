#!/bin/bash

exit 1

# # -----------------------------
# # Bootstrap backend enablement script
# # -----------------------------
# action=${1:-"enable"}
# BACKEND_DIR=${2:-"terraform/backend"}

# ENABLED_STATE="backend.tf"
# DISABLED_STATE="backend.tf.disabled"

# # Check if the backend configuration file already exists
# if [[ -f "${BACKEND_DIR}/${DISABLED_STATE}" && "$action" == "enable" ]]; then
#     mv "${BACKEND_DIR}/${DISABLED_STATE}" "${BACKEND_DIR}/${ENABLED_STATE}"
#     echo "Bootstrap backend enabled."
# elif [[ -f "${BACKEND_DIR}/${ENABLED_STATE}" && "$action" == "disable" ]]; then
#     mv "${BACKEND_DIR}/${ENABLED_STATE}" "${BACKEND_DIR}/${DISABLED_STATE}"
#     echo "Bootstrap backend disabled."
# else
#     echo "No action taken. Either the backend is already in the desired state or the expected file does not exist."
# fi