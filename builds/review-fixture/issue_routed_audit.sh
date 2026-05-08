#!/usr/bin/env bash
# Review-fixture audit: issue-routed scenario (automated review testing only).
#
# One issue with finding_kind=security and one with finding_kind=staleness, both required.
# Expected runner-derived concerns: { security: true, freshness: true, skipped: false, incomplete: false }.
set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_root="$(cd "${_script_dir}/../.." && pwd)"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/get-audit-check-id.sh"

readonly _debCheckModule="${_repo_root}/src/review/audit-checks/deb-installed-version.sh"
readonly _stalenessCheckModule="${_repo_root}/src/review/audit-checks/installer-validated-staleness.sh"
_idDeb=$(auditCheckIdFromModulePath "${_debCheckModule}") || exit 1
_idStaleness=$(auditCheckIdFromModulePath "${_stalenessCheckModule}") || exit 1
readonly _idDeb _idStaleness

printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"issue","finding_kind":"security","severity":"high","detail":"Routed security issue."},{"audit_check_id":"%s","outcome":"issue","finding_kind":"staleness","detail":"Routed freshness issue."}],"required_check_ids":["%s","%s"]}\n' \
    "${_idDeb}" "${_idStaleness}" "${_idDeb}" "${_idStaleness}"
