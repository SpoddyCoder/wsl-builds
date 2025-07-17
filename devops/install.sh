#!/usr/bin/env bash

SCRIPT_DIR="devops"

if [ ! -z $INSTALL_TERRAFORM ]; then
    if ! isComponentInstalled "terraform" "$@"; then
        source ${SCRIPT_DIR}/install_terraform.sh
        recordComponentSuccess "terraform"
    else
        warnComponentAlreadyInstalled "terraform"
    fi
fi

if [ ! -z $INSTALL_PACKER ]; then
    if ! isComponentInstalled "packer" "$@"; then
        source ${SCRIPT_DIR}/install_packer.sh
        recordComponentSuccess "packer"
    else
        warnComponentAlreadyInstalled "packer"
    fi
fi

if [ ! -z $INSTALL_KUBECTL ]; then
    if ! isComponentInstalled "kubectl" "$@"; then
        source ${SCRIPT_DIR}/install_kubectl.sh
        recordComponentSuccess "kubectl"
    else
        warnComponentAlreadyInstalled "kubectl"
    fi
fi 