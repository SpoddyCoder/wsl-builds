#!/usr/bin/env bash

SCRIPT_DIR="biscuit"

if [ ! -z $INSTALL_UPDATE ]; then
    source ${SCRIPT_DIR}/install_update.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_QOL ]; then
    source ${SCRIPT_DIR}/install_qol.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_X11 ]; then
    source ${SCRIPT_DIR}/install_x11.sh
    BUILD_UPDATED=true
fi
