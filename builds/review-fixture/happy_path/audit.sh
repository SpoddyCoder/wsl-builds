#!/usr/bin/env bash
# Review-fixture audit: happy-path scenario (automated review testing only).
#
# Emits a deterministic measurement-only envelope with all required checks passing.
# Expected runner-derived concerns: { security: false, freshness: false, skipped: false, incomplete: false }.
#
# No jq and no network; derive check id with the shared helper for parity with real audits.
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
_idCli=$(auditCheckIdFromModulePath "$(auditCheckModulePath cli-reported-version)") || exit 1
readonly _idCli

########################################################
# Emit Measurement JSON
#
printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"passed","detail":"All required checks pass."}],"required_check_ids":["%s"]}\n' \
    "${_idCli}" "${_idCli}"
