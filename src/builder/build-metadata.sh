#!/usr/bin/env bash
# Per-build metadata. Call registerBuildMetadata from "<build-dir>/conf.sh".

# Args: BUILD_DIR_NAME BUILD_VER VALID_INSTALL_COMPONENTS_CSV NUM_ADDITIONAL_ARGS
# shellcheck disable=SC2034
registerBuildMetadata() {
    BUILD_DIR_NAME="$1"
    BUILD_VER="$2"
    VALID_INSTALL_COMPONENTS="$3"
    NUM_ADDITIONAL_ARGS="$4"
    BUILD_NAME="${BUILD_DIR_NAME} v${BUILD_VER}"
}
