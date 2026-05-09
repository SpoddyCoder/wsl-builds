#!/usr/bin/env bash
# Review-fixture audit: skipped-only scenario (automated review testing only).
#
# One skipped row; no required check ids and no issues.
# Expected runner-derived concerns: { skipped: true, others: false }.
set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_root="$(cd "${_script_dir}/../../.." && pwd)"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/get-audit-check-id.sh"

readonly _semverModule="${_repo_root}/src/review/audit-checks/upstream-semver-drift.sh"
_idSemver=$(auditCheckIdFromModulePath "${_semverModule}") || exit 1
readonly _idSemver

printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"skipped","detail":"Not applicable for this fixture."}],"required_check_ids":[]}\n' \
    "${_idSemver}"
