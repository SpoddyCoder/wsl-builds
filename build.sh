#!/usr/bin/env bash
set -e

# source user config + helpers
TOOL_DIR=$(dirname "$0")
# shellcheck source=src/print.sh
source "${TOOL_DIR}"/src/print.sh
# Prefer WSL_BUILDS_CONF (shared host file); else repo-root wsl-builds.conf. shellcheck source=wsl-builds.conf.example
if [ -n "${WSL_BUILDS_CONF:-}" ]; then
    if [ ! -r "${WSL_BUILDS_CONF}" ]; then
        printError "WSL_BUILDS_CONF is set but not readable: ${WSL_BUILDS_CONF}"
        exit 1
    fi
    # shellcheck source=wsl-builds.conf.example
    source "${WSL_BUILDS_CONF}"
    printInfo "Using: ${WSL_BUILDS_CONF}"
else
    if [ ! -r "${TOOL_DIR}/wsl-builds.conf" ]; then
        printError "No wsl-builds.conf found. Run ./wsl-builds-conf.sh"
        exit 1
    fi
    # shellcheck source=wsl-builds.conf.example
    source "${TOOL_DIR}/wsl-builds.conf"
    printInfo "Using: ${TOOL_DIR}/wsl-builds.conf"
fi
# shellcheck source=src/arg-helpers.sh
source "${TOOL_DIR}"/src/arg-helpers.sh
# shellcheck source=src/install-helpers.sh
source "${TOOL_DIR}"/src/install-helpers.sh
# shellcheck source=src/build-metadata.sh
source "${TOOL_DIR}"/src/build-metadata.sh
# shellcheck disable=SC2034 # consumed by src/install-helpers.sh after sourcing
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
# shellcheck source=/dev/null # build-dir conf.sh chosen at runtime via $1
source "${BUILD_DIR}"/conf.sh

# show available components if only build dir is provided
if [ "$#" == "1" ]; then
    showUsage
    showAvailableComponents "$1"
    exit 1
fi

# BUILD_NAME is set by registerBuildMetadata in ${BUILD_DIR}/conf.sh

# build arg checks
min_num_args=$((NUM_ADDITIONAL_ARGS + 1))  # we require min 1 arg in any scenario
components_passed=false
if (containsValidComponent "$2"); then
    min_num_args=$((NUM_ADDITIONAL_ARGS + 2))  # if passing components, then we require min 2 args
    components_passed=true
fi
if [ "$#" -lt "$min_num_args" ]; then

    printError "This build requires additional arguments"
    exit 1

fi
max_num_args=$((NUM_ADDITIONAL_ARGS + 2))
if (isBuildForced "$@"); then
    max_num_args=$((NUM_ADDITIONAL_ARGS + 3))
fi
if [ "$#" -gt "$max_num_args" ]; then

    printError "Too many arguments provided"
    exit 1

fi
# Validate components if they are provided (regardless of force flag)
if [ "$#" -ge "2" ] && [ "$NUM_ADDITIONAL_ARGS" == "0" ] && ! (containsValidComponent "$2"); then

    printError "Invalid build component(s)"
    showAvailableComponents "$1"
    exit 1

fi

# install the build
if [ "$components_passed" == "true" ]; then
    declareInstallComponents "$2"
fi
printInfo "Building $BUILD_DIR_NAME v${BUILD_VER}"
BUILD_UPDATED=false
# shellcheck source=/dev/null # build-dir install.sh chosen at runtime via $1
source "${BUILD_DIR}"/install.sh
if [ "$BUILD_UPDATED" == "false" ]; then

    printInfo "No changes made by the '$1' builder."
    exit 0

fi
