#!/usr/bin/env bash
# Maintainer debug harness for the automated builds review.
#
# Modes:
#   run-check  — invoke one src/review/audit-checks/<name>.sh module directly
#   run-audit  — run one builds/<build>/<slug>/audit.sh (validates measurement envelope)
#   run-review — run ./review/component-review.sh against one build + token
#   run-e2e    — convenience wrapper: run-audit then run-review (default --build review-fixture)
#
# Output options:
#   default    — concise summary on stderr; raw JSON on stdout where applicable
#   --json     — print the relevant JSON payload to stdout (no pretty-print)
#   --pretty   — pretty-print the JSON payload via jq .
#   --show-concerns — also derive and print the runner-owned concerns object (run-audit / run-e2e)
#
# Spec refs: docs/automated-builds-review-v1-spec.md
# Fixture: builds/review-fixture/ (single source for Bats + this harness)
#
# Does not install dependencies; requires jq + bash on PATH (same as component-review.sh).
set -euo pipefail

_SCRIPT_REVIEW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../src/common/bootstrap-common.sh
source "${_SCRIPT_REVIEW_DIR}/../src/common/bootstrap-common.sh"
resolveRepoRootFromSourcePath "${BASH_SOURCE[0]}" ".." || exit 1
export REPO_ROOT

# shellcheck source=../src/common/print.sh
source "${REPO_ROOT}/src/common/print.sh"

RUNNER_BASENAME="$(basename "${BASH_SOURCE[0]}")"

# shellcheck source=../src/review/review-debug.impl.sh
source "${REPO_ROOT}/src/review/review-debug.impl.sh"

reviewDebugMain "$@"
