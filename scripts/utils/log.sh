#!/usr/bin/env bash
set -euo pipefail

# detect TTY
if [[ -t 1 ]]; then
    COLOR=1
else
    COLOR=0
fi

# colors
if (( COLOR )); then
    red=$'\e[31m'
    green=$'\e[32m'
    yellow=$'\e[33m'
    blue=$'\e[34m'
    reset=$'\e[0m'
else
    red=""
    green=""
    yellow=""
    blue=""
    reset=""
fi

# helpers
log()   { printf "%s\n" "$*"; }
ok()    { printf "${green}[OK] %s${reset}\n" "$*"; }
warn()  { printf "${yellow}[WARN] %s${reset}\n" "$*"; }
error() { printf "${red}[ERR] %s${reset}\n" "$*" >&2; }
info()  { printf "${blue}[INFO] %s${reset}\n" "$*"; }