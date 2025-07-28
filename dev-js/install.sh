#!/usr/bin/env bash

SCRIPT_DIR="dev-js"

if [ ! -z $INSTALL_NODE ]; then
    if ! isComponentInstalled "node" "$@"; then
        source ${SCRIPT_DIR}/install_node.sh
        recordComponentSuccess "node"
    else
        warnComponentAlreadyInstalled "node"
    fi
fi

if [ ! -z $INSTALL_NPM ]; then
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

if [ ! -z $INSTALL_YARN ]; then
    if ! isComponentInstalled "yarn" "$@"; then
        source ${SCRIPT_DIR}/install_yarn.sh
        recordComponentSuccess "yarn"
    else
        warnComponentAlreadyInstalled "yarn"
    fi
fi

if [ ! -z $INSTALL_NVM ]; then
    if ! isComponentInstalled "nvm" "$@"; then
        source ${SCRIPT_DIR}/install_nvm.sh
        recordComponentSuccess "nvm"
    else
        warnComponentAlreadyInstalled "nvm"
    fi
fi

if [ ! -z $INSTALL_QOL ]; then
    if ! isComponentInstalled "qol" "$@"; then
        source ${SCRIPT_DIR}/install_qol.sh
        recordComponentSuccess "qol"
    else
        warnComponentAlreadyInstalled "qol"
    fi
fi

if [ ! -z $INSTALL_REACT ]; then
    if ! isComponentInstalled "react" "$@"; then
        source ${SCRIPT_DIR}/install_react.sh
        recordComponentSuccess "react"
    else
        warnComponentAlreadyInstalled "react"
    fi
fi

if [ ! -z $INSTALL_NEXTJS ]; then
    if ! isComponentInstalled "nextjs" "$@"; then
        source ${SCRIPT_DIR}/install_nextjs.sh
        recordComponentSuccess "nextjs"
    else
        warnComponentAlreadyInstalled "nextjs"
    fi
fi

if [ ! -z $INSTALL_VUE ]; then
    if ! isComponentInstalled "vue" "$@"; then
        source ${SCRIPT_DIR}/install_vue.sh
        recordComponentSuccess "vue"
    else
        warnComponentAlreadyInstalled "vue"
    fi
fi

if [ ! -z $INSTALL_ANGULAR ]; then
    if ! isComponentInstalled "angular" "$@"; then
        source ${SCRIPT_DIR}/install_angular.sh
        recordComponentSuccess "angular"
    else
        warnComponentAlreadyInstalled "angular"
    fi
fi

if [ ! -z $INSTALL_EXPRESS ]; then
    if ! isComponentInstalled "express" "$@"; then
        source ${SCRIPT_DIR}/install_express.sh
        recordComponentSuccess "express"
    else
        warnComponentAlreadyInstalled "express"
    fi
fi 