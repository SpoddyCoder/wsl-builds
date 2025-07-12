#!/usr/bin/env bash

SCRIPT_DIR="devops-aws"

if [ ! -z $INSTALL_AWSCLI ] && ! (aws --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_awscli.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_QOL ]; then
    source ${SCRIPT_DIR}/install_qol.sh
    BUILD_UPDATED=true
fi