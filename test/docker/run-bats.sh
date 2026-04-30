#!/usr/bin/env bash
# Test image entrypoint: copy harness wsl-builds.conf to repo root, run all *.bats in this directory.
# Repo is copied into the image at build time (no bind mount). Do not run on the host (overwrites repo-root wsl-builds.conf).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"
/bin/cp -f "${SCRIPT_DIR}/wsl-builds.conf.container" "${REPO_ROOT}/wsl-builds.conf"
exec bats "$SCRIPT_DIR"
