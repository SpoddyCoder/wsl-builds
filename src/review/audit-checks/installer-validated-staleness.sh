#!/usr/bin/env bash
# Reusable audit check: installer_validated age vs max days (catalogue: installer-validated-staleness.sh).
#
# Spec: Audit-check module output (v1).
# Usage: installer-validated-staleness.sh <check_id> <YYYY-MM-DD> <max_age_days>
#
# Empty <YYYY-MM-DD> produces outcome skipped (manifest field not set). Invalid dates → inconclusive.

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "installer-validated-staleness.sh: jq is required; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

usage() {
    printf 'usage: %s <check_id> <YYYY-MM-DD> <max_age_days>\n' "${0##*/}" >&2
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

readonly check_id="$1"
readonly validated_raw="$2"
readonly max_days_raw="$3"

if [ -z "${validated_raw}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "skipped",
             detail: "installer_validated is not set in the maintainer manifest; staleness check skipped."
         }'
    exit 0
fi

if ! [[ "${max_days_raw}" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "installer-validated-staleness.sh: max_age_days must be a non-negative integer" >&2
    exit 1
fi
readonly max_days="${max_days_raw}"

validated_sec=$(date -u -d "${validated_raw}" +%s 2>/dev/null || true)
if [ -z "${validated_sec}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg d "${validated_raw}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "inconclusive",
             detail: ("installer_validated is not parseable as a date: " + $d),
             evidence: { installer_validated_raw: $d }
         }'
    exit 0
fi

now_sec=$(date -u +%s)
age_days=$(( (now_sec - validated_sec) / 86400 ))

if [ "${age_days}" -gt "${max_days}" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --argjson age "${age_days}" \
        --argjson max "${max_days}" \
        --arg d "${validated_raw}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "issue",
             finding_kind: "staleness",
             detail: ("installer_validated (" + $d + ") is " + ($age | tostring) + " days old; exceeds limit " + ($max | tostring) + " days."),
             evidence: {
                 installer_validated: $d,
                 installer_age_days: $age,
                 installer_staleness_max_days: $max
             }
         }'
else
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --argjson age "${age_days}" \
        --argjson max "${max_days}" \
        --arg d "${validated_raw}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "passed",
             detail: ("installer_validated is within " + ($max | tostring) + " days (" + ($age | tostring) + " days old)."),
             evidence: {
                 installer_validated: $d,
                 installer_age_days: $age,
                 installer_staleness_max_days: $max
             }
         }'
fi
exit 0
