#!/usr/bin/env bash
# Copies container-side config then runs every *.bats file in this directory (early-exit CLI + harness).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"
/bin/cp -f "${SCRIPT_DIR}/wsl-builds.conf.container" "${REPO_ROOT}/wsl-builds.conf"
exec bats "${REPO_ROOT}/test/container-isolated/"
