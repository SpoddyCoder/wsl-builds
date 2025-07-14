#!/usr/bin/env bash

SCRIPT_DIR="dev"

if [ ! -z $INSTALL_ESSENTIALS ] && ! (htop --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_essentials.sh
    recordComponentSuccess "essentials"
fi

if [ ! -z $INSTALL_QOL ]; then
    source ${SCRIPT_DIR}/install_qol.sh
    recordComponentSuccess "qol"
fi

if [ ! -z $INSTALL_VSCODE ]; then
    source ${SCRIPT_DIR}/install_vscode.sh
    recordComponentSuccess "vscode"
fi

if [ ! -z $INSTALL_CURSOR ] && ! (tree --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_cursor.sh
    recordComponentSuccess "cursor"
fi 