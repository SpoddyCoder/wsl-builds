#!/usr/bin/env bash
# Review-fixture audit: incomplete-required scenario (automated review testing only).
#
# req-a present but inconclusive (forces incomplete); req-b is required but missing from checks
# (also forces incomplete). Expected runner-derived concerns: { incomplete: true, others: false }.
set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_root="$(cd "${_script_dir}/../../.." && pwd)"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/get-audit-check-id.sh"

readonly _debCheckModule="${_repo_root}/src/review/audit-checks/deb-installed-version.sh"
readonly _stalenessCheckModule="${_repo_root}/src/review/audit-checks/installer-validated-staleness.sh"
_idDeb=$(auditCheckIdFromModulePath "${_debCheckModule}") || exit 1
_idStaleness=$(auditCheckIdFromModulePath "${_stalenessCheckModule}") || exit 1
readonly _idDeb _idStaleness

printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"inconclusive","detail":"Could not determine; required row inconclusive."}],"required_check_ids":["%s","%s"]}\n' \
    "${_idDeb}" "${_idDeb}" "${_idStaleness}"
