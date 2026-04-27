#!/usr/bin/env bash

SCRIPT_DIR="devops-aws"

if [ -n "$INSTALL_AWSCLI" ]; then
    if ! isComponentInstalled "awscli" "$@"; then
        # shellcheck source=devops-aws/install_awscli.sh
        source ${SCRIPT_DIR}/install_awscli.sh
        recordComponentSuccess "awscli"
    else
        warnComponentAlreadyInstalled "awscli"
    fi
fi

if [ -n "$INSTALL_QOL" ]; then
    if ! isComponentInstalled "qol" "$@"; then
        # shellcheck source=devops-aws/install_qol.sh
        source ${SCRIPT_DIR}/install_qol.sh
        recordComponentSuccess "qol"
    else
        warnComponentAlreadyInstalled "qol"
    fi
fi