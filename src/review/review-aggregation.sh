# Shared aggregation helper (spec: Aggregation helper (shared, v1), Aggregating to review_result,
# Required ordering (v1)). Consumes the checks array and explicit policy; outputs review_result,
# reasons, and summary. Caller supplies jq; do not install tools here.
#
# jq program: review-aggregation.jq (same directory).

_reviewAggJqPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/review-aggregation.jq"

# Emit one JSON object on stdout: { "review_result", "reasons", "summary" }.
# Inputs:
#   $1 — checks: JSON array of normalized check objects (see Audit item outcomes (normalized)).
#   $2 — required_check_ids: JSON array of strings (check id values required for a complete story).
#   $3 — optional custom_issue_policy: JSON object, default {}. Optional key routes_by_check_id:
#        object mapping check id to "1", "2", or "none" — applies to issue rows whose finding_kind
#        is custom or unknown (and to issue rows with no finding_kind, treated as custom).
#
# Precedence: 3 if any required check is missing, inconclusive, or any issue is unclassified for
# top-level rollup; then 1 (security-class issues or policy route "1"); then 2 (staleness /
# upstream_drift or route "2"); else 0.
reviewAggregateFromChecks() {
    local checks_json="${1:?checks JSON array required}"
    local required_ids_json="${2:?required_check_ids JSON array required}"
    local custom_policy_json="$3"
    if [ -z "${custom_policy_json}" ]; then
        custom_policy_json='{}'
    fi
    if [[ ! -f "${_reviewAggJqPath}" ]]; then
        printf '%s\n' "reviewAggregateFromChecks: missing jq program at ${_reviewAggJqPath}" >&2
        return 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        printf '%s\n' 'reviewAggregateFromChecks: jq is required; see CONTRIBUTING.md (Automated builds review tooling).' >&2
        return 1
    fi
    jq -cn \
        --argjson checks "${checks_json}" \
        --argjson requiredIds "${required_ids_json}" \
        --argjson policy "${custom_policy_json}" \
        -f "${_reviewAggJqPath}"
}
