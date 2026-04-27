#!/usr/bin/env bash

SCRIPT_DIR="dev"

if [ -n "$INSTALL_ESSENTIALS" ]; then
    if ! isComponentInstalled "essentials" "$@"; then
        # shellcheck source=dev/install_essentials.sh
        source ${SCRIPT_DIR}/install_essentials.sh
        recordComponentSuccess "essentials"
    else
        warnComponentAlreadyInstalled "essentials"
    fi
fi

if [ -n "$INSTALL_QOL" ]; then
    if ! isComponentInstalled "qol" "$@"; then
        # shellcheck source=dev/install_qol.sh
        source ${SCRIPT_DIR}/install_qol.sh
        recordComponentSuccess "qol"
    else
        warnComponentAlreadyInstalled "qol"
    fi
fi

if [ -n "$INSTALL_VSCODE" ]; then
    if ! isComponentInstalled "vscode" "$@"; then
        # shellcheck source=dev/install_vscode.sh
        source ${SCRIPT_DIR}/install_vscode.sh
        recordComponentSuccess "vscode"
    else
        warnComponentAlreadyInstalled "vscode"
    fi
fi

if [ -n "$INSTALL_CURSOR" ]; then
    if ! isComponentInstalled "cursor" "$@"; then
        # shellcheck source=dev/install_cursor.sh
        source ${SCRIPT_DIR}/install_cursor.sh
        recordComponentSuccess "cursor"
    else
        warnComponentAlreadyInstalled "cursor"
    fi
fi 