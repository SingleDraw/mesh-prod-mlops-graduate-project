#!/usr/bin/env bash
set -euo pipefail

# ============================
# Script to inject variables into template files
# It takes a directory, file extension, and key-value pairs 
# to replace in all files with the given extension 
# in the directory and its subdirectories.
# ============================

# usage: 
# ./path-to/inject-vars.sh "./target/dir" "ext|*" \
#     "foo" "FOO" \
#     "foo" "BAR"

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Do not source this script"
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/log.sh"
# shellcheck disable=SC1091
. "$(dirname "$(realpath "${0}")")/../utils/sed.sh"

# shellcheck disable=SC2154
if [[ $# -lt 4 ]]; then error "Usage: $0 <dir> <ext> [key value ...]"; exit 1; fi

# ============================
# Template variable injection
# ============================
dir="$1"
ext="$2"

ext_cmd="-name *.$ext"

if [[ "$ext" == "*" ]]; then
    ext_cmd=""
fi

shift 2

(( $# % 2 == 0 )) || {
    error "key/value mismatch"
    exit 1
}

ok "Injecting variables into *.$ext files in $dir/ ..."

sed_args=()

while (( $# )); do
    key="$1"
    val="$2"
    shift 2
    sed_args+=(-e "s|$key|$val|g")
done

# shellcheck disable=SC2086
find "$dir" -type f $ext_cmd -exec "${SED_I[@]}" "${sed_args[@]}" {} +

ok "Variable injection completed."

# -- end of script --