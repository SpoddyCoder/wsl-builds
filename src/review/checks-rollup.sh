# Shared aggregation helper (spec: Aggregation helper (shared, v1), Aggregating to review_result,
# Required ordering (v1)). Consumes the checks array and explicit policy; outputs review_result,
# review_result_label, review_concerns, reasons, and summary. Caller supplies jq; do not install tools here.
#
# jq program: checks-rollup.jq (same directory).

_rollupJqPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/checks-rollup.jq"

# Emit one JSON object on stdout: review_result, review_result_label, review_concerns, reasons, summary.
# Inputs:
#   $1 — checks: JSON array of normalized check objects (see Audit item outcomes (normalized)).
#   $2 — required_check_ids: JSON array of strings (audit_check_id values required for a complete story).
#   $3 — optional custom_issue_policy: JSON object, default {}. Optional key routes_by_audit_check_id
#        maps audit_check_id to "security", "freshness", or "none" for issue rows not classified by
#        finding_kind alone (custom or missing). "none" excludes the row from concern flags.
#
# Precedence: 2 if the story is incomplete (required missing/inconclusive or unrouted issue); else 1
# if any security- or freshness-bucket issue (review_concerns flags set independently); else 0.
emitRollupFromChecks() {
    local checks_json="${1:?checks JSON array required}"
    local required_ids_json="${2:?required_check_ids JSON array required}"
    local custom_policy_json="$3"
    if [ -z "${custom_policy_json}" ]; then
        custom_policy_json='{}'
    fi
    if [[ ! -f "${_rollupJqPath}" ]]; then
        printf '%s\n' "emitRollupFromChecks: missing jq program at ${_rollupJqPath}" >&2
        return 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        printf '%s\n' 'emitRollupFromChecks: jq is required; see CONTRIBUTING.md (Automated builds review tooling).' >&2
        return 1
    fi
    jq -cn \
        --argjson checks "${checks_json}" \
        --argjson requiredIds "${required_ids_json}" \
        --argjson policy "${custom_policy_json}" \
        -f "${_rollupJqPath}"
}
