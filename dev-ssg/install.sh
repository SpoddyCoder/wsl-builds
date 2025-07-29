#!/usr/bin/env bash

SCRIPT_DIR="dev-ssg"

if [ ! -z $INSTALL_HUGO ]; then
    if ! isComponentInstalled "hugo" "$@"; then
        source ${SCRIPT_DIR}/install_hugo.sh
        recordComponentSuccess "hugo"
    else
        warnComponentAlreadyInstalled "hugo"
    fi
fi

if [ ! -z $INSTALL_JEKYLL ]; then
    if ! isComponentInstalled "jekyll" "$@"; then
        source ${SCRIPT_DIR}/install_jekyll.sh
        recordComponentSuccess "jekyll"
    else
        warnComponentAlreadyInstalled "jekyll"
    fi
fi 