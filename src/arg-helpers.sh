#!/usr/bin/env bash
# helper functions for arg / components checks

# inline command
# shows usage information
showUsage() {
    echo
    echo "Usage: $0 <build-dir> <component>[,<component>...] [additionalargs]... [--force]"
}

# inline command
# $1 - build name
# shows available components for the build
showAvailableComponents() {
    echo
    echo "Available components for $1:"
    IFS=',' read -r -a components <<< "$VALID_INSTALL_COMPONENTS"
    for component in "${components[@]}"; do
        echo "  $component"
    done
    echo
}

# inline command
# shows available build directories
showAvailableBuildDirs() {
    echo
    echo "Available build directories:"
    for dir in "${TOOL_DIR}"/*/; do
        if [ -d "$dir" ] && [ -f "$dir/conf.sh" ]; then
            echo "  $(basename "$dir")"
        fi
    done | sort
    echo
}

# inline command
# $1 - csv list of selected install components
# declares a variable INSTALL_SOMECOMPONENT=true if the selected component is valid (case insensitive)
# exits with error if selected component not valid
declareInstallComponents() {
    IFS=',' read -r -a selected_opts <<< "$1"
    for component in "${selected_opts[@]}"; do
        if (isValidComponent $component); then
            component_var="${component//-/_}"
            declare -g "INSTALL_${component_var^^}=true"
        else
            printError "Invalid build component(s)"
            showAvailableComponents "${HOSTNAME}"
            exit 1
        fi
    done
}

# faux function call (call as subprocess) 
# $1 - csv list of selected install components
# exits 0 or 1
containsValidComponent() {
    IFS=',' read -r -a selected_opts <<< "$1"
    for component in "${selected_opts[@]}"; do
        if (isValidComponent $component); then
            exit 0
        fi
    done
    exit 1
}

# faux function call (call as subprocess) 
# $1 - component to check
# exits 0 or 1
isValidComponent() {
    IFS=',' read -r -a valid_opts <<< "$VALID_INSTALL_COMPONENTS"
    for valid_component in "${valid_opts[@]}"; do
        # case insensitive
        if [ "${1^^}" == "${valid_component^^}" ]; then
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