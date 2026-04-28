#!/usr/bin/env bash
# Per-build metadata. Call registerBuildMetadata from "<build-dir>/conf.sh".

# Args: HOSTNAME BUILD_VER VALID_INSTALL_COMPONENTS_CSV NUM_ADDITIONAL_ARGS [PROJECT_DIR]
# Optionally sets PROJECT_DIR when a fifth argument is passed (used by ai-resources).
# shellcheck disable=SC2034
registerBuildMetadata() {
    HOSTNAME="$1"
    BUILD_VER="$2"
    VALID_INSTALL_COMPONENTS="$3"
    NUM_ADDITIONAL_ARGS="$4"
    BUILD_NAME="${HOSTNAME} v${BUILD_VER}"
    if [ "${5:-}" != "" ]; then
        PROJECT_DIR="$5"
    fi
}
