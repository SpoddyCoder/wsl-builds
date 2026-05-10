#!/usr/bin/env bash
# Interactive (or --noninteractive) setup for WSL_BUILDS_CONF (Windows host) or ~/.wsl-builds.conf.
set -euo pipefail

# shellcheck source=src/common/bootstrap-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src/common/bootstrap-common.sh"
resolveRepoRootFromSourcePath "${BASH_SOURCE[0]}" || exit 1
# shellcheck source=src/common/print.sh
source "${REPO_ROOT}/src/common/print.sh"
# shellcheck source=src/configure/configure-main.sh
source "${REPO_ROOT}/src/configure/configure-main.sh"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mainWizard "$@"
fi
