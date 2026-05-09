#!/usr/bin/env bash
# Lint the repo, build the Bats test image, and run tests in Docker (embedded copy of the repo).
set -euo pipefail
# shellcheck source=../src/common/bootstrap-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/common/bootstrap-common.sh"
resolveRepoRootFromSourcePath "${BASH_SOURCE[0]}" ".." || exit 1
cd "$REPO_ROOT"

readonly stepRule='----------------------------------------------------------------------------'

printStepBanner() {
	printf '\n%s\n' "$stepRule"
	printf '  %s\n' "$1"
	printf '%s\n\n' "$stepRule"
}

printStepSummaryOk() {
	printf '%s\n\n' "✓ $1"
}

handleStepError() {
	local ec=$?
	printf >&2 '\n%s\n' "$stepRule"
	printf >&2 '  Step failed (exit %s)\n' "$ec"
	printf >&2 '%s\n' "$stepRule"
	exit "$ec"
}
trap handleStepError ERR

printStepBanner 'Step 1 / 3 — Lint (ShellCheck)'
./test/lint.sh
printStepSummaryOk 'Lint finished with no reported issues.'

printStepBanner 'Step 2 / 3 — Docker image build (tag: wsl-builds-test)'
docker build -f test/docker/Dockerfile -t wsl-builds-test .
printStepSummaryOk 'Docker image built successfully.'

printStepBanner 'Step 3 / 3 — Bats in container (docker run)'
docker run --rm wsl-builds-test
printStepSummaryOk 'All container tests completed successfully.'

trap - ERR
printf '%s\n' '✓ Full test run finished successfully.'
