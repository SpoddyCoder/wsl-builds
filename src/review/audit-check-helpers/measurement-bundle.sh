# shellcheck shell=bash
# Measurement helpers for composing audit-check module outputs into checks[] (v1).
#
# Spec: Audit helper library (shared measurement); helpers must not set review verdict fields,
# concerns — computed by component-review.sh from checks + policy.
#
# Source from <slug>/audit.sh or from audit-checks modules. Requires jq on PATH (same as
# component-review / aggregation); do not install tools here.

# Append one logical-line stdout check object from an audit-checks/*.sh module to a checks array.
#
# Arguments:
#   $1 — full check line (single JSON object check row; optional .evidence object when present).
#   $2 — checks JSON array accumulator.
#
# Stdout: one compact JSON array. Stderr: jq diagnostics on parse/validation failure.
# Returns non-zero when jq fails.
appendCheckLineToChecksArray() {
    local check_line="${1:?appendCheckLineToChecksArray: check line required}"
    local checks_json="${2:?appendCheckLineToChecksArray: checks JSON array required}"
    if ! command -v jq >/dev/null 2>&1; then
        printf '%s\n' 'appendCheckLineToChecksArray: jq is required; see CONTRIBUTING.md (Automated builds review tooling).' >&2
        return 1
    fi
    jq -cn \
        --argjson check "${check_line}" \
        --argjson checks "${checks_json}" \
        '
        if ($check | type) != "object" then error("check line must be a JSON object") else . end
        | if ($check | has("evidence")) and (($check.evidence | type) != "object")
          then error("check.evidence must be an object when present")
          else .
          end
        | if ($checks | type) != "array" then error("checks accumulator must be a JSON array") else . end
        | ($checks + [$check])
        '
}
