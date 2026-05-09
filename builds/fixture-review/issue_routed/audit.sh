#!/usr/bin/env bash
# Review-fixture audit: issue-routed scenario (automated review testing only).
#
# One issue with finding_kind=security and one with finding_kind=staleness, both required.
# Expected runner-derived concerns: { security: true, freshness: true, skipped: false, incomplete: false }.
set -euo pipefail

########################################################
# Source Helpers
#
# shellcheck source=../../../src/common/bootstrap-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/src/common/bootstrap-common.sh"
resolveRepoRootFromAuditScript "${BASH_SOURCE[0]}" || exit 1

# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/audit-check-module-path.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/get-audit-check-id.sh"

########################################################
# Resolve Required Check IDs
#
_idDeb=$(auditCheckIdFromModulePath "$(auditCheckModulePath deb-installed-version)") || exit 1
_idStaleness=$(auditCheckIdFromModulePath "$(auditCheckModulePath installer-validated-staleness)") || exit 1
readonly _idDeb _idStaleness

########################################################
# Emit Measurement JSON
#
printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"issue","finding_kind":"security","severity":"high","detail":"Routed security issue."},{"audit_check_id":"%s","outcome":"issue","finding_kind":"staleness","detail":"Routed freshness issue."}],"required_check_ids":["%s","%s"]}\n' \
    "${_idDeb}" "${_idStaleness}" "${_idDeb}" "${_idStaleness}"
