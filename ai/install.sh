#!/usr/bin/env bash

SCRIPT_DIR="ai"

if [ ! -z $INSTALL_CUDA124 ]; then
    if ! isComponentInstalled "cuda124" "$@"; then
        source ${SCRIPT_DIR}/install_cuda12-4.sh
        recordComponentSuccess "cuda124"
    else
        warnComponentAlreadyInstalled "cuda124"
    fi
fi
