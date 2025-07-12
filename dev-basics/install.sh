#!/usr/bin/env bash

SCRIPT_DIR="dev-basics"

if [ ! -z $INSTALL_ESSENTIALS ] && ! (htop --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_essentials.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_PYTHON3 ] && ! (pip3 --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_python3.sh
    BUILD_UPDATED=true
fi 