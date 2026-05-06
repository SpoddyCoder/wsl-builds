# shellcheck shell=bash
# Measurement helpers for composing audit-check module envelopes into checks[] / evidence (v1).
#
# Spec: Audit helper library (shared measurement); helpers must not set review_result,
# reasons, or summary — judgment stays in audit_<component>.sh via reviewAggregateFromChecks.
#
# Source from audit_<component>.sh or from audit-checks modules. Requires jq on PATH (same as
# component-review / aggregation); do not install tools here.

# Convert one logical-line stdout envelope from an audit-checks/*.sh module into a compact JSON
# fragment suitable for merging before aggregation:
#   {"checks":[<normalized check object>],"evidence":{...}}
#
# Arguments:
#   $1 — full envelope line (single JSON object with required .check; optional .evidence).
#
# Stdout: one compact JSON object. Stderr: jq diagnostics on parse/validation failure.
# Returns non-zero when jq fails.
reviewMeasurementBundleFromCheckEnvelopeLine() {
    local envelope_line="${1:?reviewMeasurementBundleFromCheckEnvelopeLine: envelope line required}"
    if ! command -v jq >/dev/null 2>&1; then
        printf '%s\n' 'reviewMeasurementBundleFromCheckEnvelopeLine: jq is required; see CONTRIBUTING.md (Automated builds review tooling).' >&2
        return 1
    fi
    printf '%s\n' "${envelope_line}" | jq -ce '
        if type != "object" then error("envelope must be a JSON object") else . end
        | if (.check | type) != "object" then error("envelope missing .check object") else . end
        | { checks: [.check], evidence: (.evidence // {}) }
    '
}

# Shallow-merge two measurement bundles (checks concatenated; evidence object keys merged, b wins on collision).
#
# Arguments:
#   $1 — first bundle JSON: { "checks": [...], "evidence": {...} }
#   $2 — second bundle JSON (same shape).
#
# Identity: reviewMergeMeasurementBundles '{"checks":[],"evidence":{}}' '<any bundle>' === <any bundle>.
reviewMergeMeasurementBundles() {
    local bundle_a="${1:?reviewMergeMeasurementBundles: first bundle required}"
    local bundle_b="${2:?reviewMergeMeasurementBundles: second bundle required}"
    if ! command -v jq >/dev/null 2>&1; then
        printf '%s\n' 'reviewMergeMeasurementBundles: jq is required; see CONTRIBUTING.md (Automated builds review tooling).' >&2
        return 1
    fi
    jq -cn \
        --argjson a "${bundle_a}" \
        --argjson b "${bundle_b}" \
        '
        if ($a | type) != "object" or ($b | type) != "object" then error("bundles must be JSON objects") else . end
        | if (($a.checks // null) | type) != "array" or (($b.checks // null) | type) != "array"
          then error("each bundle must have a .checks array") else . end
        | {
            checks: ($a.checks + $b.checks),
            evidence: (($a.evidence // {}) * ($b.evidence // {}))
          }
        '
}
