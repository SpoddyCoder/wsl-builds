#!/usr/bin/env bash
# Copies harness wsl-builds.conf into the image's /repo, then runs every *.bats file here (CLI early-exit + test-fixture harness).
# Intended as the Docker image CMD (repo is copied at image build time; no bind mount).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"
/bin/cp -f "${SCRIPT_DIR}/wsl-builds.conf.container" "${REPO_ROOT}/wsl-builds.conf"
exec bats "${REPO_ROOT}/test/container-isolated/"
