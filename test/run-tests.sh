#!/usr/bin/env bash
# Lint the repo, build the bats test image, and run suites in Docker (embedded copy of the repo).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
docker build -f test/Dockerfile -t wsl-builds-test .
printStepSummaryOk 'Docker image built successfully.'

printStepBanner 'Step 3 / 3 — Container-isolated tests (docker run)'
docker run --rm wsl-builds-test
printStepSummaryOk 'All container tests completed successfully.'

trap - ERR
printf '%s\n' '✓ Full test run finished successfully.'
