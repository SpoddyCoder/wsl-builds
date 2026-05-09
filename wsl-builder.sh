#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=src/common/bootstrap-common.sh
source "$(cd "$(dirname "$0")" && pwd)/src/common/bootstrap-common.sh"
resolveRepoRootFromBuilderPath "$0" || exit 1
# Deprecated alias: builds/*/install.sh stubs still use TOOL_DIR; equals REPO_ROOT. New code should use REPO_ROOT; stub lines migrate in Phase 4.
# shellcheck disable=SC2034 # consumed by builds/<name>/install.sh after sourcing
TOOL_DIR="${REPO_ROOT}"

# shellcheck source=src/common/print.sh
source "${REPO_ROOT}/src/common/print.sh"
# shellcheck source=src/builder/main.sh
source "${REPO_ROOT}/src/builder/main.sh"
