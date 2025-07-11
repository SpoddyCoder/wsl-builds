#!/usr/bin/env bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -z $INSTALL_CONDA ] && ! (conda --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/conda/install_conda.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_CUDA124 ] && [ ! -f /etc/apt/preferences.d/cuda-repository-pin-600 ]; then
    source ${SCRIPT_DIR}/cuda/install_cuda12-4.sh
    BUILD_UPDATED=true
fi
