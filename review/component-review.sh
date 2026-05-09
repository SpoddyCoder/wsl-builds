#!/usr/bin/env bash
# Component review (spec Phase 1): invoke <slug>/audit.sh, merge runner fields, validate merged JSON,
# persist validated merged JSON to <slug>/review.result.json.
set -euo pipefail

_SCRIPT_REVIEW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../src/common/bootstrap-common.sh
source "${_SCRIPT_REVIEW_DIR}/../src/common/bootstrap-common.sh"
resolveRepoRootFromSourcePath "${BASH_SOURCE[0]}" ".." || exit 1
export REPO_ROOT

# shellcheck source=../src/common/print.sh
source "${REPO_ROOT}/src/common/print.sh"

loadWslBuildsConfOrExit

# shellcheck source=../src/builder/builds-root.sh
source "${REPO_ROOT}/src/builder/builds-root.sh"
resolveBuildsRootFromRepoRoot "${REPO_ROOT}" || exit 1

if ! command -v jq >/dev/null 2>&1; then
    printError "jq is required for component-review.sh. Install jq and see CONTRIBUTING.md (Automated builds review tooling)."
    exit 1
fi

RUNNER_BASENAME=$(basename "${BASH_SOURCE[0]}")

# shellcheck source=../src/review/component-review.impl.sh
source "${REPO_ROOT}/src/review/component-review.impl.sh"

componentReviewMain "$@"
