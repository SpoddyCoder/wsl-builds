#!/usr/bin/env bash
set -e

# source user config + helpers
TOOL_DIR=$(dirname $0)
source ${TOOL_DIR}/wsl-builds.conf
source ${TOOL_DIR}/src/print.sh
source ${TOOL_DIR}/src/arg-helpers.sh
source ${TOOL_DIR}/src/install-helpers.sh
BUILD_INFO_FILE=~/.wsl-build.info

# initial build dir checks
if [ "$#" == "0" ]; then

    showUsage
    showAvailableBuildDirs
    exit 1

fi
if [ ! -d "${TOOL_DIR}/$1" ] || [ ! -f "${TOOL_DIR}/$1/conf.sh" ]; then

    printError "Build directory '$1' not found"
    exit 1

fi

# source the build conf
BUILD_DIR="${TOOL_DIR}/$1"
source ${BUILD_DIR}/conf.sh

# show available components if only build dir is provided
if [ "$#" == "1" ]; then
    showUsage
    showAvailableComponents "$1"
    exit 1
fi

BUILD_NAME="${HOSTNAME} v${BUILD_VER}"

# build arg checks
min_num_args=$(($NUM_ADDITIONAL_ARGS + 1))  # we require min 1 arg in any scenario
components_passed=false
if (containsValidComponent $2); then
    min_num_args=$(($NUM_ADDITIONAL_ARGS + 2))  # if passing components, then we require min 2 args
    components_passed=true
fi

# check if already installed (check for individual component conflicts)
if [ "$components_passed" == "true" ]; then
    # Check if any version of this build has the requested components installed
    build_pattern="${HOSTNAME} v"
    
    if grep -qs "^${build_pattern}" ${BUILD_INFO_FILE} && ! (isBuildForced $@); then
        # Get all installed components for this build (from all versions)
        installed_components=$(grep "^${build_pattern}" ${BUILD_INFO_FILE} | sed 's/.*(\([^)]*\)).*/\1/' | tr ',' '\n' | sort -u | tr '\n' ' ')
        
        # Check each requested component against installed components
        requested_components=$(echo "$2" | tr ',' ' ')
        conflicts=()
        
        for requested_component in $requested_components; do
            # Remove any whitespace
            requested_component=$(echo "$requested_component" | xargs)
            if echo "$installed_components" | grep -q "\b${requested_component}\b"; then
                conflicts+=("$requested_component")
            fi
        done
        
        if [ ${#conflicts[@]} -gt 0 ]; then
            printError "The following components are already installed for ${HOSTNAME}: ${conflicts[*]}"
            echo "Either remove these components from your command or use --force to reinstall."
            echo "Current build stack:"
            cat ${BUILD_INFO_FILE}
            exit 1
        fi
    fi
else
    # Check for build without components (any version)
    check_build_without_components="${HOSTNAME} v"
    if grep -qs "^${check_build_without_components}[0-9.]*$" ${BUILD_INFO_FILE} && ! (isBuildForced $@); then
        existing_version=$(grep "^${check_build_without_components}[0-9.]*$" ${BUILD_INFO_FILE} | sed 's/.*\(v[0-9.]*\).*/\1/' | head -1)
        printError "${HOSTNAME} ${existing_version} is already installed..."
        echo "Use --force to reinstall this build."
        echo "Current build stack:"
        cat ${BUILD_INFO_FILE}
        exit 1
    fi
fi
if [ "$#" -lt "$min_num_args" ]; then

    printError "This build requires additional arguments"
    exit 1

fi
max_num_args=$(($NUM_ADDITIONAL_ARGS + 2))
if (isBuildForced $@); then
    max_num_args=$(($NUM_ADDITIONAL_ARGS + 3))
fi
if [ "$#" -gt "$max_num_args" ]; then

    printError "Too many arguments provided"
    exit 1

fi
# Validate components if they are provided (regardless of force flag)
if [ "$#" -ge "2" ] && [ "$NUM_ADDITIONAL_ARGS" == "0" ] && ! (containsValidComponent $2); then

    printError "Invalid build component(s)"
    showAvailableComponents "$1"
    exit 1

fi

# install the build
if [ "$components_passed" == "true" ]; then
    declareInstallComponents $2
fi
printInfo "Building $HOSTNAME v${BUILD_VER}"
BUILD_UPDATED=false
source ${BUILD_DIR}/install.sh
if [ "$BUILD_UPDATED" == "false" ]; then

    printWarning "No changes made by '$1' installer"
    exit 1

fi
