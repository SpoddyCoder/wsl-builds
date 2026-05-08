#!/usr/bin/env bash
# Review-fixture audit: policy-none-route scenario (automated review testing only).
#
# Custom-kind issue routed to "none" via custom_issue_policy.routes_by_audit_check_id.
# Expected runner-derived concerns: all false (excluded from security/freshness without forcing incomplete).
set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_root="$(cd "${_script_dir}/../.." && pwd)"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/get-audit-check-id.sh"

readonly _upstreamExactModule="${_repo_root}/src/review/audit-checks/upstream-exact-match.sh"
_idExact=$(auditCheckIdFromModulePath "${_upstreamExactModule}") || exit 1
readonly _idExact

printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"issue","finding_kind":"custom","detail":"Custom issue routed to none."}],"required_check_ids":["%s"],"custom_issue_policy":{"routes_by_audit_check_id":{"%s":"none"}}}\n' \
    "${_idExact}" "${_idExact}" "${_idExact}"
