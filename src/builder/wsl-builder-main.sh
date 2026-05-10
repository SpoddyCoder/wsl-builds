# Builder main implementation (wsl-builder-main.sh): sourced by ./wsl-builder.sh after bootstrap, REPO_ROOT, and print.sh.

loadWslBuildsConfOrExit

# shellcheck source=src/builder/builds-root.sh
source "${REPO_ROOT}/src/builder/builds-root.sh"
resolveBuildsRootFromRepoRoot "${REPO_ROOT}" || exit 1
# getFile (install-helpers.sh); optional override in wsl-builds.conf
CACHE_DIR="${CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/wsl-builds}"
# shellcheck source=src/builder/arg-helpers.sh
source "${REPO_ROOT}/src/builder/arg-helpers.sh"
# shellcheck source=src/builder/install-helpers.sh
source "${REPO_ROOT}/src/builder/install-helpers.sh"
# shellcheck source=src/builder/shell-rc.sh
source "${REPO_ROOT}/src/builder/shell-rc.sh"
# shellcheck source=src/builder/wsl-conf.sh
source "${REPO_ROOT}/src/builder/wsl-conf.sh"
# shellcheck source=src/builder/build-metadata.sh
source "${REPO_ROOT}/src/builder/build-metadata.sh"
# shellcheck disable=SC2034 # consumed by src/builder/install-helpers.sh after sourcing
BUILD_INFO_FILE=~/.wsl-build.info

# initial build dir checks
if [ "$#" == "0" ]; then

    showUsage
    showAvailableBuildDirs
    exit 1

fi
if [ ! -d "${BUILDS_ROOT}/$1" ] || [ ! -f "${BUILDS_ROOT}/$1/conf.sh" ]; then

    printError "Build directory '$1' not found"
    exit 1

fi

# source the build conf
BUILD_DIR="${BUILDS_ROOT}/$1"
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
