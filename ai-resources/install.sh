#!/usr/bin/env bash

SCRIPT_DIR="ai-resources"
PROJECT_DIR=~/ai-resources

if [ ! -z $INSTALL_SG3 ] && [ ! -f ${PROJECT_DIR}/stylegan3 ]; then
    source ${SCRIPT_DIR}/install_sg3.sh
    BUILD_UPDATED=true    
fi

if [ ! -z $INSTALL_LSD ] && [ ! -f ${PROJECT_DIR}/lucid-sonic-dreams ]; then
    source ${SCRIPT_DIR}/install_lsd.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_SPLEETER ] && [ ! -f ${PROJECT_DIR}/spleeter ]; then
    source ${SCRIPT_DIR}/install_spleeter.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_RUDALLE ] && [ ! -f ${PROJECT_DIR}/ru-dalle ]; then
    source ${SCRIPT_DIR}/install_rudalle.sh
    BUILD_UPDATED=true
fi
