#!/usr/bin/env bash
# Review-fixture audit: skipped-only scenario (automated review testing only).
#
# One skipped row; no required check ids and no issues.
# Expected runner-derived concerns: { skipped: true, others: false }.
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
_idSemver=$(auditCheckIdFromModulePath "$(auditCheckModulePath upstream-semver-drift)") || exit 1
readonly _idSemver

########################################################
# Emit Measurement JSON
#
printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"skipped","detail":"Not applicable for this fixture."}],"required_check_ids":[]}\n' \
    "${_idSemver}"
