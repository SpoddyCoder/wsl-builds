#!/usr/bin/env bash

SCRIPT_DIR="ai-resources"
# shellcheck disable=SC2034 # consumed by sibling install_*.sh scripts after sourcing
PROJECT_DIR=~/ai-resources

if [ -n "$INSTALL_SG3" ]; then
    if ! isComponentInstalled "sg3" "$@"; then
        # shellcheck source=ai-resources/install_sg3.sh
        source ${SCRIPT_DIR}/install_sg3.sh
        recordComponentSuccess "sg3"
    else
        warnComponentAlreadyInstalled "sg3"
    fi
fi

if [ -n "$INSTALL_LSD" ]; then
    if ! isComponentInstalled "lsd" "$@"; then
        # shellcheck source=ai-resources/install_lsd.sh
        source ${SCRIPT_DIR}/install_lsd.sh
        recordComponentSuccess "lsd"
    else
        warnComponentAlreadyInstalled "lsd"
    fi
fi

if [ -n "$INSTALL_SPLEETER" ]; then
    if ! isComponentInstalled "spleeter" "$@"; then
        # shellcheck source=ai-resources/install_spleeter.sh
        source ${SCRIPT_DIR}/install_spleeter.sh
        recordComponentSuccess "spleeter"
    else
        warnComponentAlreadyInstalled "spleeter"
    fi
fi

if [ -n "$INSTALL_RUDALLE" ]; then
    if ! isComponentInstalled "rudalle" "$@"; then
        # shellcheck source=ai-resources/install_rudalle.sh
        source ${SCRIPT_DIR}/install_rudalle.sh
        recordComponentSuccess "rudalle"
    else
        warnComponentAlreadyInstalled "rudalle"
    fi
fi
