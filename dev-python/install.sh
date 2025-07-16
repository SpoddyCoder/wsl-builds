#!/usr/bin/env bash

SCRIPT_DIR="dev-python"

if [ ! -z $INSTALL_CONDA ]; then
    if ! isComponentInstalled "conda" "$@"; then
        source ${SCRIPT_DIR}/install_conda.sh
        recordComponentSuccess "conda"
    else
        warnComponentAlreadyInstalled "conda"
    fi
fi

if [ ! -z $INSTALL_PYTHON3 ]; then
    if ! isComponentInstalled "python3" "$@"; then
        source ${SCRIPT_DIR}/install_python3.sh
        recordComponentSuccess "python3"
    else
        warnComponentAlreadyInstalled "python3"
    fi
fi 