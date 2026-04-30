#!/usr/bin/env bash
# Lint the repo, build the bats test image, and run suites in Docker (embedded copy of the repo).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
./test/lint.sh
docker build -t wsl-builds-test .
docker run --rm wsl-builds-test
