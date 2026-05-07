#!/usr/bin/env bash
# Reusable audit check: timed HTTP GET and jq extract (catalogue: http-json-upstream-version.sh).
# Uses audit-check-helpers/http-get-with-retry.sh (retries/timeouts per Network and flake policy v1).
#
# Spec: Audit-check module output (v1).
# Usage: http-json-upstream-version.sh <check_id> <url> <jq_filter> [max_time_seconds]
#
# <jq_filter> is a jq expression applied to the parsed JSON root (e.g. .tag_name).

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "http-json-upstream-version.sh: jq is required; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

usage() {
    printf 'usage: %s <check_id> <url> <jq_filter> [max_time_seconds]\n' "${0##*/}" >&2
}

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    usage
    exit 1
fi

readonly check_id="$1"
readonly url="$2"
readonly jq_filter="$3"
readonly max_time="${4:-30}"

_helper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../audit-check-helpers" && pwd)"
# shellcheck source=/dev/null
source "${_helper_dir}/http-get-with-retry.sh"

if ! body=$(httpGetWithRetry "${url}" "${max_time}"); then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg u "${url}" \
        '{
             check: {
                 audit_check_id: $audit_check_id,
                 outcome: "inconclusive",
                 detail: ("HTTP fetch failed or gave non-success status for " + $u + ".")
             },
             evidence: { upstream_url: $u }
         }'
    exit 0
fi

extracted=""
if extracted=$(printf '%s' "${body}" | jq -e -r "${jq_filter}" 2>/dev/null | head -n1); then
    :
else
    extracted=""
fi

if [ -z "${extracted}" ] || [ "${extracted}" = "null" ]; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg u "${url}" \
        '{
             check: {
                 audit_check_id: $audit_check_id,
                 outcome: "inconclusive",
                 detail: "jq filter produced no usable string from HTTP JSON response."
             },
             evidence: { upstream_url: $u }
         }'
    exit 0
fi

jq -cn \
    --arg audit_check_id "${check_id}" \
    --arg u "${url}" \
    --arg val "${extracted}" \
    '{
         check: {
             audit_check_id: $audit_check_id,
             outcome: "passed",
             detail: ("Fetched upstream value: " + $val)
         },
         evidence: {
             upstream_url: $u,
             http_json_extracted: $val
         }
     }'
exit 0
