#!/usr/bin/env bash

SCRIPT_DIR="ai-basics"

if [ ! -z $INSTALL_CUDA124 ] && [ ! -f /etc/apt/preferences.d/cuda-repository-pin-600 ]; then
    source ${SCRIPT_DIR}/install_cuda12-4.sh
    BUILD_UPDATED=true
fi
