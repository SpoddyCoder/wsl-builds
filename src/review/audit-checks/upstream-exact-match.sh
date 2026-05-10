#!/usr/bin/env bash
# Reusable audit check: string equality after trim (catalogue: upstream-exact-match.sh).
#
# Spec: Audit-check module output (v1).
# Usage: upstream-exact-match.sh <check_id> <expected> <observed>
#
# Empty expected → skipped. Empty observed with non-empty expected → inconclusive.

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "upstream-exact-match.sh: jq is required; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

usage() {
    printf 'usage: %s <check_id> <expected> <observed>\n' "${0##*/}" >&2
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

readonly check_id="$1"
expected="$2"
observed="$3"

trim() {
    local s="${1:-}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "${s}"
}

expected=$(trim "${expected}")
observed=$(trim "${observed}")

if [ -z "${expected}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "skipped",
             detail: "last_known_upstream is not set; exact match check skipped."
         }'
    exit 0
fi

if [ -z "${observed}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg exp "${expected}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "inconclusive",
             detail: "Observed upstream/version is empty; cannot compare to last_known_upstream.",
             evidence: { last_known_upstream: $exp }
         }'
    exit 0
fi

if [ "${expected}" = "${observed}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg exp "${expected}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "passed",
             detail: "Observed value matches last_known_upstream.",
             evidence: {
                 last_known_upstream: $exp,
                 observed_upstream: $exp
             }
         }'
else
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg exp "${expected}" \
        --arg obs "${observed}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "issue",
             finding_kind: "upstream_drift",
             detail: ("Observed \"" + $obs + "\" does not match last_known_upstream \"" + $exp + "\"."),
             evidence: {
                 last_known_upstream: $exp,
                 observed_upstream: $obs
             }
         }'
fi
exit 0
