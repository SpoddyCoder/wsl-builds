#!/usr/bin/env bash

SCRIPT_DIR="dev-python"

if [ ! -z $INSTALL_CONDA ] && ! (conda --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_conda.sh
    recordComponentSuccess "conda"
fi

if [ ! -z $INSTALL_PYTHON3 ] && ! (pip3 --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_python3.sh
    recordComponentSuccess "python3"
fi 