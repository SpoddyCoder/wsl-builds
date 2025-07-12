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

    echo
    echo "Usage: $0 <build-dir> [buildoptions,...] [additionalargs]... [--force]"
    echo
    exit 1

fi
if [ ! -d "${TOOL_DIR}/$1" ]; then

    printError "Build directory '$1' not found"
    exit 1

fi

# source the build conf
BUILD_DIR="${TOOL_DIR}/$1"
source ${BUILD_DIR}/conf.sh

# show available options if only build dir is provided
if [ "$#" == "1" ]; then
    echo
    echo "Usage: $0 <build-dir> [buildoptions,...] [additionalargs]... [--force]"
    showAvailableOptions "$1"
    exit 1
fi

BUILD_NAME="${HOSTNAME} v${BUILD_VER}"

# build arg checks
min_num_args=$(($NUM_ADDITIONAL_ARGS + 1))  # we require min 1 arg in any scenario
options_passed=false
if (containsValidOption $2); then
    min_num_args=$(($NUM_ADDITIONAL_ARGS + 2))  # if passing options, then we require min 2 args
    options_passed=true
fi

# check if already installed (check for individual option conflicts)
if [ "$options_passed" == "true" ]; then
    # Check if any version of this build has the requested options installed
    build_pattern="${HOSTNAME} v"
    
    if grep -qs "^${build_pattern}" ${BUILD_INFO_FILE} && ! (isBuildForced $@); then
        # Get all installed options for this build (from all versions)
        installed_options=$(grep "^${build_pattern}" ${BUILD_INFO_FILE} | sed 's/.*(\([^)]*\)).*/\1/' | tr ',' '\n' | sort -u | tr '\n' ' ')
        
        # Check each requested option against installed options
        requested_options=$(echo "$2" | tr ',' ' ')
        conflicts=()
        
        for requested_option in $requested_options; do
            # Remove any whitespace
            requested_option=$(echo "$requested_option" | xargs)
            if echo "$installed_options" | grep -q "\b${requested_option}\b"; then
                conflicts+=("$requested_option")
            fi
        done
        
        if [ ${#conflicts[@]} -gt 0 ]; then
            printError "The following options are already installed for ${HOSTNAME}: ${conflicts[*]}"
            echo "Either remove these options from your command or use --force to reinstall."
            echo "Current build stack:"
            cat ${BUILD_INFO_FILE}
            exit 1
        fi
    fi
else
    # Check for build without options (any version)
    check_build_without_options="${HOSTNAME} v"
    if grep -qs "^${check_build_without_options}[0-9.]*$" ${BUILD_INFO_FILE} && ! (isBuildForced $@); then
        existing_version=$(grep "^${check_build_without_options}[0-9.]*$" ${BUILD_INFO_FILE} | sed 's/.*\(v[0-9.]*\).*/\1/' | head -1)
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
if [ "$#" == "2" ] && [ "$NUM_ADDITIONAL_ARGS" == "0" ] && ! (containsValidOption $2); then

    printError "Invalid build option(s)"
    showAvailableOptions "$1"
    exit 1

fi

# install the build
if [ "$options_passed" == "true" ]; then
    declareInstallOptions $2
fi
printInfo "Building $HOSTNAME v${BUILD_VER}"
BUILD_UPDATED=false
source ${BUILD_DIR}/install.sh
if [ "$BUILD_UPDATED" == "false" ]; then

    printWarning "No changes made by '$1' installer"
    exit 1

fi

# update build info
if [ ! -f ${BUILD_INFO_FILE} ]; then
    printInfo "Creating ${BUILD_INFO_FILE}"
    base_os_id=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release | tr -d '"')
    base_os_version="$(awk -F= '$1=="VERSION" { print $2 ;}' /etc/os-release | tr -d '"')"
    echo "${base_os_id} ${base_os_version}" >> ${BUILD_INFO_FILE}
    cat ${BUILD_INFO_FILE}
fi
if [ "$options_passed" == "true" ]; then
    echo "${BUILD_NAME} ($2)" >> ${BUILD_INFO_FILE}
else
    echo "${BUILD_NAME}" >> ${BUILD_INFO_FILE}
fi
printInfo "$(tail -1 ${BUILD_INFO_FILE}) installed!"
