#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to initialize a new repository from a template
# Usage: ./init-template.sh <template_name>
# This script copies the contents of the specified template directory from 'templates/' to the directory specified by LOCAL_REPOS.
# ============================

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Do not source this script"
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/log.sh"

# check if LOCAL_REPOS variable is set
if [[ -z "${LOCAL_REPOS:-}" ]]; then error "LOCAL_REPOS variable is not set. Please set it in the .env file."; exit 1; fi

# shellcheck disable=SC2154
if [[ $# -ne 1 ]]; then error "Usage: $0 <template_name>"; exit 1; fi

template_name="$1"

if [[ ! -d "templates/$template_name" ]]; then
	error "Template '$template_name' does not exist in the 'templates' directory."
	exit 1
fi

if [[ -d "$LOCAL_REPOS/$template_name" ]]; then
	# shellcheck disable=SC2154
	# shellcheck disable=SC2059
	warn "Directory '$LOCAL_REPOS/$template_name' already exists. Do you want to overwrite it? (y/n)"
	read -r answer
	if [[ "$answer" != "y" ]]; then
		error "Aborting."
		exit 1
	fi
fi

# shellcheck disable=SC2154
ok "Distributing template to $LOCAL_REPOS/$template_name..."

# shellcheck disable=SC2115
rm -rf "$LOCAL_REPOS/$template_name" && mkdir -p "$LOCAL_REPOS/$template_name"
cp -r "templates/$template_name/." "$LOCAL_REPOS/$template_name/"

