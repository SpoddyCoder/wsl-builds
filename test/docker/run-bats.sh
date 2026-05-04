#!/usr/bin/env bash
# Test image entrypoint: copy harness wsl-builds.conf to repo root, run each Bats file in its own bats(1) process (fixed order).
# Re-copies the harness before the wizard suite so repo-root wsl-builds.conf is deterministic between processes.
# Repo is copied into the image at build time (no bind mount). Do not run on the host (overwrites repo-root wsl-builds.conf).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"
unset WSL_BUILDS_CONF

fail=0

/bin/cp -f "${SCRIPT_DIR}/wsl-builds.conf" "${REPO_ROOT}/wsl-builds.conf"
bats "${SCRIPT_DIR}/builder-tests.bats" || fail=1

/bin/cp -f "${SCRIPT_DIR}/wsl-builds.conf" "${REPO_ROOT}/wsl-builds.conf"
bats "${SCRIPT_DIR}/conf-wizard-tests.bats" || fail=1

/bin/cp -f "${SCRIPT_DIR}/wsl-builds.conf" "${REPO_ROOT}/wsl-builds.conf"
bats "${SCRIPT_DIR}/commands-tests.bats" || fail=1

exit "$fail"
