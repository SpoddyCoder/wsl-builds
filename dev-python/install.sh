#!/usr/bin/env bash

SCRIPT_DIR="dev-python"

if [ -n "$INSTALL_CONDA" ]; then
    if ! isComponentInstalled "conda" "$@"; then
        # shellcheck source=dev-python/install_conda.sh
        source ${SCRIPT_DIR}/install_conda.sh
        recordComponentSuccess "conda"
    else
        warnComponentAlreadyInstalled "conda"
    fi
fi

if [ -n "$INSTALL_PYTHON3" ]; then
    if ! isComponentInstalled "python3" "$@"; then
        # shellcheck source=dev-python/install_python3.sh
        source ${SCRIPT_DIR}/install_python3.sh
        recordComponentSuccess "python3"
    else
        warnComponentAlreadyInstalled "python3"
    fi
fi 