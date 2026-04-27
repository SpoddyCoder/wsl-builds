#!/usr/bin/env bash

SCRIPT_DIR="dev-bash"

if [ ! -z $INSTALL_SHELLCHECK ]; then
    if ! isComponentInstalled "shellcheck" "$@"; then
        source ${SCRIPT_DIR}/install_shellcheck.sh
        recordComponentSuccess "shellcheck"
    else
        warnComponentAlreadyInstalled "shellcheck"
    fi
fi
