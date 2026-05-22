#!/usr/bin/env bash
set -euo pipefail

# ============================
# Safe sed -i, cross-platform
# ============================

if [[ "$(uname -s)" == "Darwin" ]]; then
    # shellcheck disable=SC2034
    SED_I=(sed -i '')
else
    # shellcheck disable=SC2034
    SED_I=(sed -i)
fi
