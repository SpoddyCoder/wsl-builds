#!/usr/bin/env bash
# Advisory review for the shellcheck component (dev-bash build).
#
# Measurement: one required check id `shellcheck_cli`. Aggregation via
# reviewAggregateFromChecks (spec: Aggregation helper shared v1).
#
# Stdout: one JSON object line (spec: Runner validation after audit v1). Stderr: diagnostics only.
# Does not install packages; if jq is missing, component-review.sh fails before this script runs.

set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_root="$(cd "${_script_dir}/../.." && pwd)"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/review-aggregation.sh"

readonly requiredCheckIdsJson='["shellcheck_cli"]'

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "audit_shellcheck.sh: jq is required to emit JSON; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

emitFinalJson() {
    local checks_json="$1"
    local evidence_json="$2"
    local agg_json
    agg_json=$(reviewAggregateFromChecks "${checks_json}" "${requiredCheckIdsJson}" '') || return 1
    jq -cn \
        --argjson checks "${checks_json}" \
        --argjson evidence "${evidence_json}" \
        --argjson agg "${agg_json}" \
        '{
            component_reviewer_version: 1,
            checks: $checks,
            evidence: $evidence
        } + $agg'
}

if ! command -v shellcheck >/dev/null 2>&1; then
    checks_json=$(jq -cn '[{
      "id": "shellcheck_cli",
      "outcome": "inconclusive",
      "detail": "shellcheck is not installed or not on PATH; run the shellcheck component install first."
    }]')
    emitFinalJson "${checks_json}" '{}'
    exit 0
fi

shellcheck_version=$(shellcheck --version 2>/dev/null | sed -n 's/^version:[[:space:]]*//p' | head -n1 || true)
if [ -z "${shellcheck_version}" ]; then
    shellcheck_version="(no version line from shellcheck --version)"
fi

checks_json=$(jq -cn --arg ver "${shellcheck_version}" '[{
  "id": "shellcheck_cli",
  "outcome": "passed",
  "detail": ("Reported package/version line: " + $ver)
}]')
evidence_json=$(jq -cn --arg ver "${shellcheck_version}" '{shellcheck_reported_version: $ver}')
emitFinalJson "${checks_json}" "${evidence_json}"
exit 0
