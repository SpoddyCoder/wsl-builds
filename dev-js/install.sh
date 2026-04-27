#!/usr/bin/env bash

SCRIPT_DIR="dev-js"

if [ -n "$INSTALL_NODE" ]; then
    if ! isComponentInstalled "node" "$@"; then
        # shellcheck source=dev-js/install_node.sh
        source ${SCRIPT_DIR}/install_node.sh
        recordComponentSuccess "node"
    else
        warnComponentAlreadyInstalled "node"
    fi
fi

if [ -n "$INSTALL_NPM" ]; then
    if ! isComponentInstalled "npm" "$@"; then
        # NPM is included with Node.js, so just verify it's available
        if command -v npm >/dev/null 2>&1; then
            printInfo "NPM is already available (installed with Node.js)"
            recordComponentSuccess "npm"
        else
            printError "NPM not found. Please install Node.js first."
            exit 1
        fi
    else
        warnComponentAlreadyInstalled "npm"
    fi
fi

if [ -n "$INSTALL_YARN" ]; then
    if ! isComponentInstalled "yarn" "$@"; then
        # shellcheck source=dev-js/install_yarn.sh
        source ${SCRIPT_DIR}/install_yarn.sh
        recordComponentSuccess "yarn"
    else
        warnComponentAlreadyInstalled "yarn"
    fi
fi

if [ -n "$INSTALL_NVM" ]; then
    if ! isComponentInstalled "nvm" "$@"; then
        # shellcheck source=dev-js/install_nvm.sh
        source ${SCRIPT_DIR}/install_nvm.sh
        recordComponentSuccess "nvm"
    else
        warnComponentAlreadyInstalled "nvm"
    fi
fi

if [ -n "$INSTALL_ESSENTIALS" ]; then
    if ! isComponentInstalled "essentials" "$@"; then
        # shellcheck source=dev-js/install_essentials.sh
        source ${SCRIPT_DIR}/install_essentials.sh
        recordComponentSuccess "essentials"
    else
        warnComponentAlreadyInstalled "essentials"
    fi
fi

if [ -n "$INSTALL_REACT" ]; then
    if ! isComponentInstalled "react" "$@"; then
        # shellcheck source=dev-js/install_react.sh
        source ${SCRIPT_DIR}/install_react.sh
        recordComponentSuccess "react"
    else
        warnComponentAlreadyInstalled "react"
    fi
fi

if [ -n "$INSTALL_NEXTJS" ]; then
    if ! isComponentInstalled "nextjs" "$@"; then
        # shellcheck source=dev-js/install_nextjs.sh
        source ${SCRIPT_DIR}/install_nextjs.sh
        recordComponentSuccess "nextjs"
    else
        warnComponentAlreadyInstalled "nextjs"
    fi
fi

if [ -n "$INSTALL_VUE" ]; then
    if ! isComponentInstalled "vue" "$@"; then
        # shellcheck source=dev-js/install_vue.sh
        source ${SCRIPT_DIR}/install_vue.sh
        recordComponentSuccess "vue"
    else
        warnComponentAlreadyInstalled "vue"
    fi
fi

if [ -n "$INSTALL_ANGULAR" ]; then
    if ! isComponentInstalled "angular" "$@"; then
        # shellcheck source=dev-js/install_angular.sh
        source ${SCRIPT_DIR}/install_angular.sh
        recordComponentSuccess "angular"
    else
        warnComponentAlreadyInstalled "angular"
    fi
fi

if [ -n "$INSTALL_EXPRESS" ]; then
    if ! isComponentInstalled "express" "$@"; then
        # shellcheck source=dev-js/install_express.sh
        source ${SCRIPT_DIR}/install_express.sh
        recordComponentSuccess "express"
    else
        warnComponentAlreadyInstalled "express"
    fi
fi 