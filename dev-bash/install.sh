#!/usr/bin/env bash

SCRIPT_DIR="dev-bash"

if [ -n "$INSTALL_SHELLCHECK" ]; then
    if ! isComponentInstalled "shellcheck" "$@"; then
        # shellcheck source=dev-bash/install_shellcheck.sh
        source ${SCRIPT_DIR}/install_shellcheck.sh
        recordComponentSuccess "shellcheck"
    else
        warnComponentAlreadyInstalled "shellcheck"
    fi
fi
