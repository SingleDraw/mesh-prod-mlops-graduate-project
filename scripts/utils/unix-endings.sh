#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/sed.sh"

# ============================
# Convert line endings to Unix format
# ============================
unix_endings() {
    local files=("$@")
    for file in "${files[@]}"; do
        printf "Converting %s to Unix line endings...\n" "$file"
        if [[ -f "$file" ]]; then
            "${SED_I[@]}" $'s/\r$//' "$file"
        fi
    done
}

# usage when sourced: 
#   unix_endings file1.txt file2.txt
# usage when run as script: 
#   ./unix-endings.sh file1.txt file2.txt

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <file1> <file2> ..."
        exit 1
    fi
    unix_endings "$@"
fi

# -- end of script --