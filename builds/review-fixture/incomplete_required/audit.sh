#!/usr/bin/env bash
# Review-fixture audit: incomplete-required scenario (automated review testing only).
#
# req-a present but inconclusive (forces incomplete); req-b is required but missing from checks
# (also forces incomplete). Expected runner-derived concerns: { incomplete: true, others: false }.
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
_idDeb=$(auditCheckIdFromModulePath "$(auditCheckModulePath deb-installed-version)") || exit 1
_idStaleness=$(auditCheckIdFromModulePath "$(auditCheckModulePath installer-validated-staleness)") || exit 1
readonly _idDeb _idStaleness

########################################################
# Emit Measurement JSON
#
printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"inconclusive","detail":"Could not determine; required row inconclusive."}],"required_check_ids":["%s","%s"]}\n' \
    "${_idDeb}" "${_idDeb}" "${_idStaleness}"
