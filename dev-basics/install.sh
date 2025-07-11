#!/usr/bin/env bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -z $INSTALL_ESSENTIALS ] && ! (htop --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/essentials/install_essentials.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_PYTHON3 ] && ! (pip3 --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/python3/install_python3.sh
    BUILD_UPDATED=true
fi 