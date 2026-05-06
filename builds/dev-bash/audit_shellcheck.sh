#!/usr/bin/env bash
# Advisory review for the shellcheck component (dev-bash build).
#
# Measurement: audit-check module cli-reported-version (check id shellcheck_cli).
# Folded into checks/evidence via review-measurement-bundle.sh; aggregation via
# reviewAggregateFromChecks (spec: Aggregation helper shared v1).
#
# Stdout: one JSON object line (spec: Runner validation after audit v1). Stderr: diagnostics only.
# Does not install packages; if jq is missing, component-review.sh fails before this script runs.

set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_root="$(cd "${_script_dir}/../.." && pwd)"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/review-aggregation.sh"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/review-measurement-bundle.sh"

readonly requiredCheckIdsJson='["shellcheck_cli"]'
readonly _emptyMeasurementBundle='{"checks":[],"evidence":{}}'
readonly _cliCheckModule="${_repo_root}/src/review/audit-checks/cli-reported-version.sh"

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

envelope_line=$(bash "${_cliCheckModule}" shellcheck_cli shellcheck) || {
    printf '%s\n' 'audit_shellcheck.sh: cli-reported-version.sh failed' >&2
    exit 1
}
bundle=$(reviewMeasurementBundleFromCheckEnvelopeLine "${envelope_line}") || exit 1
merged=$(reviewMergeMeasurementBundles "${_emptyMeasurementBundle}" "${bundle}") || exit 1
checks_json=$(printf '%s\n' "${merged}" | jq -c '.checks')
evidence_json=$(printf '%s\n' "${merged}" | jq -c '.evidence')
emitFinalJson "${checks_json}" "${evidence_json}"
exit 0
