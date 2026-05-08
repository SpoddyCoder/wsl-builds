#!/usr/bin/env bash
# Test image entrypoint: run each Bats file in its own bats(1) process (fixed order).
# Builder and review tests install harness wsl-builds.conf into isolated $HOME; wizard tests use fake $HOME only.
# Repo is copied into the image at build time (no bind mount).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"
unset WSL_BUILDS_CONF

fail=0

bats "${SCRIPT_DIR}/builder-tests.bats" || fail=1

bats "${SCRIPT_DIR}/review-tests.bats" || fail=1

bats "${SCRIPT_DIR}/review-fixture-tests.bats" || fail=1

bats "${SCRIPT_DIR}/conf-wizard-tests.bats" || fail=1

bats "${SCRIPT_DIR}/commands-tests.bats" || fail=1

exit "$fail"
