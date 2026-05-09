#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=src/common/bootstrap-common.sh
source "$(cd "$(dirname "$0")" && pwd)/src/common/bootstrap-common.sh"
resolveRepoRootFromBuilderPath "$0" || exit 1

# shellcheck source=src/common/print.sh
source "${REPO_ROOT}/src/common/print.sh"
# shellcheck source=src/builder/wsl-builder-main.sh
source "${REPO_ROOT}/src/builder/wsl-builder-main.sh"
