#!/usr/bin/env bash

SCRIPT_DIR="dev-basics"

if [ ! -z $INSTALL_ESSENTIALS ] && ! (htop --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_essentials.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_QOL ]; then
    source ${SCRIPT_DIR}/install_qol.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_VSCODE ]; then
    source ${SCRIPT_DIR}/install_vscode.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_CURSOR ] && ! (tree --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_cursor.sh
    BUILD_UPDATED=true
fi 