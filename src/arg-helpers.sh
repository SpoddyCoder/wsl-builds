#!/usr/bin/env bash
# helper functions for arg / options checks

# inline command
# $1 - csv list of selected install options
# declares a variable INSTALL_SOMEOPTION=true if the selected option is valid (case insensitive)
# exits with error if selected option not valid
declareInstallOptions() {
    IFS=',' read -r -a selected_opts <<< "$1"
    for option in "${selected_opts[@]}"; do
        if (isValidOption $option); then
            declare -g "INSTALL_${option^^}=true"
        else
            printError "Invalid install option '$option'. Valid options: '$VALID_INSTALL_OPTIONS'"
            exit 1
        fi
    done
}

# faux function call (call as subprocess) 
# $1 - csv list of selected install options
# exits 0 or 1
containsValidOption() {
    IFS=',' read -r -a selected_opts <<< "$1"
    for option in "${selected_opts[@]}"; do
        if (isValidOption $option); then
            exit 0
        fi
    done
    exit 1
}

# faux function call (call as subprocess) 
# $1 - option to check
# exits 0 or 1
isValidOption() {
    IFS=',' read -r -a valid_opts <<< "$VALID_INSTALL_OPTIONS"
    for valid_option in "${valid_opts[@]}"; do
        # case insensitive
        if [ "${1^^}" == "${valid_option^^}" ]; then
            exit 0
        fi
    done
    exit 1
}

# faux function call (call as subprocess) 
# $# - argument list
# exits 0 or 1
isBuildForced() {
    for arg in "$@"; do
        if [ "$arg" == "--force" ]; then
            exit 0
        fi
    done
    exit 1
}