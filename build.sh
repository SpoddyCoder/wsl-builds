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
    echo
    echo "Available options for $1: $VALID_INSTALL_OPTIONS"
    echo
    exit 1
fi

BUILD_NAME="${HOSTNAME} v${BUILD_VER}"

# check if already installed
check_build="${HOSTNAME} v"
if grep -qs "${check_build}" ${BUILD_INFO_FILE} && ! (isBuildForced $@); then

    printError "${HOSTNAME} is already installed..."
    cat ${BUILD_INFO_FILE}
    exit 1

fi

# build arg checks
min_num_args=$(($NUM_ADDITIONAL_ARGS + 1))  # we require min 1 arg in any scenario
options_passed=false
if (containsValidOption $2); then
    min_num_args=$(($NUM_ADDITIONAL_ARGS + 2))  # if passing options, then we require min 2 args
    options_passed=true
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

# & instance hostname
updateHostname $HOSTNAME
