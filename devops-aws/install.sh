#!/usr/bin/env bash

SCRIPT_DIR="devops-aws"

if [ ! -z $INSTALL_AWSCLI ]; then
    if ! isComponentInstalled "awscli" "$@"; then
        source ${SCRIPT_DIR}/install_awscli.sh
        recordComponentSuccess "awscli"
    else
        warnComponentAlreadyInstalled "awscli"
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