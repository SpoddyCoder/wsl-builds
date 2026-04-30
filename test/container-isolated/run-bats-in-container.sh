#!/usr/bin/env bash
# Copies container-side config then runs every *.bats file in this directory (early-exit CLI + harness).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
/bin/cp -f "${REPO_ROOT}/wsl-builds.conf.container.example" "${REPO_ROOT}/wsl-builds.conf"
exec bats "${REPO_ROOT}/test/container-isolated/"
