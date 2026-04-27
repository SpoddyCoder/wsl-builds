#!/usr/bin/env bash

SCRIPT_DIR="dev-ssg"

if [ -n "$INSTALL_HUGO" ]; then
    if ! isComponentInstalled "hugo" "$@"; then
        # shellcheck source=dev-ssg/install_hugo.sh
        source ${SCRIPT_DIR}/install_hugo.sh
        recordComponentSuccess "hugo"
    else
        warnComponentAlreadyInstalled "hugo"
    fi
fi

if [ -n "$INSTALL_JEKYLL" ]; then
    if ! isComponentInstalled "jekyll" "$@"; then
        # shellcheck source=dev-ssg/install_jekyll.sh
        source ${SCRIPT_DIR}/install_jekyll.sh
        recordComponentSuccess "jekyll"
    else
        warnComponentAlreadyInstalled "jekyll"
    fi
fi 