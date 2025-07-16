#!/usr/bin/env bash

SCRIPT_DIR="dev"

if [ ! -z $INSTALL_ESSENTIALS ]; then
    if ! isComponentInstalled "essentials" "$@"; then
        source ${SCRIPT_DIR}/install_essentials.sh
        recordComponentSuccess "essentials"
    else
        warnComponentAlreadyInstalled "essentials"
    fi
fi

if [ ! -z $INSTALL_QOL ]; then
    if ! isComponentInstalled "qol" "$@"; then
        source ${SCRIPT_DIR}/install_qol.sh
        recordComponentSuccess "qol"
    else
        warnComponentAlreadyInstalled "qol"
    fi
fi

if [ ! -z $INSTALL_VSCODE ]; then
    if ! isComponentInstalled "vscode" "$@"; then
        source ${SCRIPT_DIR}/install_vscode.sh
        recordComponentSuccess "vscode"
    else
        warnComponentAlreadyInstalled "vscode"
    fi
fi

if [ ! -z $INSTALL_CURSOR ]; then
    if ! isComponentInstalled "cursor" "$@"; then
        source ${SCRIPT_DIR}/install_cursor.sh
        recordComponentSuccess "cursor"
    else
        warnComponentAlreadyInstalled "cursor"
    fi
fi 