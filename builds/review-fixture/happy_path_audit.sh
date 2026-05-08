#!/usr/bin/env bash
# Review-fixture audit: happy-path scenario (automated review testing only).
#
# Emits a deterministic measurement-only envelope with all required checks passing.
# Expected runner-derived concerns: { security: false, freshness: false, skipped: false, incomplete: false }.
#
# No jq and no network; derive check id with the shared helper for parity with real audits.
set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_root="$(cd "${_script_dir}/../.." && pwd)"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/get-audit-check-id.sh"

readonly _cliCheckModule="${_repo_root}/src/review/audit-checks/cli-reported-version.sh"
_idCli=$(auditCheckIdFromModulePath "${_cliCheckModule}") || exit 1
readonly _idCli

printf '{"component_reviewer_version":1,"checks":[{"audit_check_id":"%s","outcome":"passed","detail":"All required checks pass."}],"required_check_ids":["%s"]}\n' \
    "${_idCli}" "${_idCli}"
