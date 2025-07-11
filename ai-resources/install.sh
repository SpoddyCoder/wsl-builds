#!/usr/bin/env bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR=~/ai-resources

if [ ! -z $INSTALL_SG3 ] && [ ! -f ${PROJECT_DIR}/stylegan3 ]; then
    source ${SCRIPT_DIR}/stylegan3/install_sg3.sh
    BUILD_UPDATED=true    
fi

if [ ! -z $INSTALL_LSD ] && [ ! -f ${PROJECT_DIR}/lucid-sonic-dreams ]; then
    source ${SCRIPT_DIR}/lucid-sonic-dreams/install_lsd.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_SPLEETER ] && [ ! -f ${PROJECT_DIR}/spleeter ]; then
    source ${SCRIPT_DIR}/spleeter/install_spleeter.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_RUDALLE ] && [ ! -f ${PROJECT_DIR}/ru-dalle ]; then
    source ${SCRIPT_DIR}/ru-dalle/install_ru-dalle.sh
    BUILD_UPDATED=true
fi
