#!/usr/bin/env bash

SCRIPT_DIR="devops"

if [ ! -z $INSTALL_TERRAFORM ] && ! (terraform --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_terraform.sh
    recordComponentSuccess "terraform"
fi

if [ ! -z $INSTALL_KUBECTL ] && ! (kubectl version --client) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_kubectl.sh
    recordComponentSuccess "kubectl"
fi 