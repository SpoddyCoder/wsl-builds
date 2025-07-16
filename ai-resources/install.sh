#!/usr/bin/env bash

SCRIPT_DIR="ai-resources"
PROJECT_DIR=~/ai-resources

if [ ! -z $INSTALL_SG3 ]; then
    if ! isComponentInstalled "sg3" "$@"; then
        source ${SCRIPT_DIR}/install_sg3.sh
        recordComponentSuccess "sg3"
    else
        warnComponentAlreadyInstalled "sg3"
    fi
fi

if [ ! -z $INSTALL_LSD ]; then
    if ! isComponentInstalled "lsd" "$@"; then
        source ${SCRIPT_DIR}/install_lsd.sh
        recordComponentSuccess "lsd"
    else
        warnComponentAlreadyInstalled "lsd"
    fi
fi

if [ ! -z $INSTALL_SPLEETER ]; then
    if ! isComponentInstalled "spleeter" "$@"; then
        source ${SCRIPT_DIR}/install_spleeter.sh
        recordComponentSuccess "spleeter"
    else
        warnComponentAlreadyInstalled "spleeter"
    fi
fi

if [ ! -z $INSTALL_RUDALLE ]; then
    if ! isComponentInstalled "rudalle" "$@"; then
        source ${SCRIPT_DIR}/install_rudalle.sh
        recordComponentSuccess "rudalle"
    else
        warnComponentAlreadyInstalled "rudalle"
    fi
fi
