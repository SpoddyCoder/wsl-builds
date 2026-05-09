#!/usr/bin/env bash
# Review-fixture audit: policy-none-route scenario (automated review testing only).
#
# Custom-kind issue routed to "none" via custom_issue_policy.routes_by_audit_check_id.
# Expected runner-derived concerns: all false (excluded from security/freshness without forcing incomplete).
set -euo pipefail

########################################################
# Source Helpers
#
# shellcheck source=../../../src/bootstrap-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/src/bootstrap-common.sh"
resolveRepoRootFromAuditScript "${BASH_SOURCE[0]}" || exit 1

# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/audit-check-module-path.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/get-audit-check-id.sh"

########################################################
# Resolve Required Check IDs
#
_idExact=$(auditCheckIdFromModulePath "$(auditCheckModulePath upstream-exact-match)") || exit 1
readonly _idExact

########################################################
# Emit Measurement JSON
#
printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"issue","finding_kind":"custom","detail":"Custom issue routed to none."}],"required_check_ids":["%s"],"custom_issue_policy":{"routes_by_audit_check_id":{"%s":"none"}}}\n' \
    "${_idExact}" "${_idExact}" "${_idExact}"
