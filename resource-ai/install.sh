#!/usr/bin/env bash
PROJECT_DIR=~/resource-ai

if [ ! -z $INSTALL_SG3 ] && [ ! -f ${PROJECT_DIR}/stylegan3 ]; then
    source stylegan3/install_sg3.sh
    BUILD_UPDATED=true    
fi

if [ ! -z $INSTALL_LSD ] && [ ! -f ${PROJECT_DIR}/lucid-sonic-dreams ]; then
    source lucid-sonic-dreams/install_lsd.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_SPLEETER ] && [ ! -f ${PROJECT_DIR}/spleeter ]; then
    source spleeter/install_spleeter.sh    
    BUILD_UPDATED=true
fi
