#!/usr/bin/env bash
# Reusable audit check: semver-style ordering (catalogue: upstream-semver-drift.sh).
# Uses sort -V (GNU coreutils); suitable for dotted numeric versions after optional "v" strip.
#
# Spec: Audit-check module output (v1).
# Usage: upstream-semver-drift.sh <check_id> <observed_version> <reference_version>
#
# If observed sorts strictly older than reference → issue (upstream_drift). Equal or newer → passed.
# Empty operands → inconclusive.

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "upstream-semver-drift.sh: jq is required; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

usage() {
    printf 'usage: %s <check_id> <observed_version> <reference_version>\n' "${0##*/}" >&2
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

readonly check_id="$1"

normalizeVersion() {
    local s="${1:-}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    s="${s#v}"
    s="${s#V}"
    printf '%s' "${s}"
}

observed=$(normalizeVersion "$2")
reference=$(normalizeVersion "$3")

if [ -z "${observed}" ] || [ -z "${reference}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        '{
             check: {
                 audit_check_id: $audit_check_id,
                 outcome: "inconclusive",
                 detail: "Missing observed or reference semver string after normalization."
             },
             evidence: {}
         }'
    exit 0
fi

if [ "${observed}" = "${reference}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg o "${observed}" \
        '{
             check: {
                 audit_check_id: $audit_check_id,
                 outcome: "passed",
                 detail: "Observed version matches reference."
             },
             evidence: {
                 observed_semver: $o,
                 reference_semver: $o
             }
         }'
    exit 0
fi

first=$(printf '%s\n%s\n' "${observed}" "${reference}" | sort -V | head -n1)
if [ "${first}" = "${observed}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg o "${observed}" \
        --arg r "${reference}" \
        '{
             check: {
                 audit_check_id: $audit_check_id,
                 outcome: "issue",
                 finding_kind: "upstream_drift",
                 detail: ("Observed version " + $o + " is behind reference " + $r + ".")
             },
             evidence: {
                 observed_semver: $o,
                 reference_semver: $r
             }
         }'
else
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg o "${observed}" \
        --arg r "${reference}" \
        '{
             check: {
                 audit_check_id: $audit_check_id,
                 outcome: "passed",
                 detail: ("Observed version " + $o + " is at or ahead of reference " + $r + ".")
             },
             evidence: {
                 observed_semver: $o,
                 reference_semver: $r
             }
         }'
fi
exit 0
