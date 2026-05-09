#!/usr/bin/env bash
# Advisory review for the shellcheck component (dev-bash build).
#
# Measurement: all six v1 catalogue modules under src/review/audit-checks/ (signal-first):
#   cli-reported-version, deb-installed-version, installer-validated-staleness,
#   http-json-upstream-version, upstream-exact-match, upstream-semver-drift.
# checks[].audit_check_id values are the module basename (.sh stripped); module orchestration and
# checks[] assembly are centralized in audit-flow.sh so this file reads as a check plan.
# Concerns policy views are computed by component-review.sh.
#
# Stdout: one JSON object line (measurement envelope for component-review.sh). Stderr: diagnostics only.
# Does not install packages. Requires jq; HTTP check requires curl (see CONTRIBUTING.md).

set -euo pipefail


########################################################
# Source Helpers and Audit Checks Library
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../../src/bootstrap-common.sh
source "${SCRIPT_DIR}/../../../src/bootstrap-common.sh"
resolveRepoRootFromAuditScript "${BASH_SOURCE[0]}" || exit 1

# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/audit-flow.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/read-manifest-scalar.sh"


########################################################
# Config + Read Manifest
#

readonly _github_latest_url='https://api.github.com/repos/koalaman/shellcheck/releases/latest'

readonly _manifest="${SCRIPT_DIR}/audit.manifest.yaml"
installer_validated=$(readManifestScalarLine "${_manifest}" installer_validated)
installer_staleness_max_days=$(readManifestScalarLine "${_manifest}" installer_staleness_max_days)
last_known_upstream=$(readManifestScalarLine "${_manifest}" last_known_upstream)
if [ -z "${installer_staleness_max_days}" ]; then
    installer_staleness_max_days='90'
fi

########################################################
# Start Audit Flow
#

readonly requiredCheckIdsJson='["cli-reported-version","deb-installed-version","installer-validated-staleness","upstream-exact-match"]'
auditFlowInit 'shellcheck/audit.sh' "${requiredCheckIdsJson}" || exit 1

########################################################
# Run audit-checks
#

auditFlowRunModuleStem cli-reported-version shellcheck || exit 1

auditFlowRunModuleStem deb-installed-version shellcheck || exit 1

auditFlowRunModuleStem installer-validated-staleness "${installer_validated}" "${installer_staleness_max_days}" || exit 1

auditFlowRunModuleStem http-json-upstream-version "${_github_latest_url}" '.tag_name' || exit 1

deb_ver=$(auditFlowEvidenceField 'deb-installed-version' 'deb_installed_version')
auditFlowRunModuleStem upstream-exact-match "${last_known_upstream}" "${deb_ver}" || exit 1

cli_ver=$(auditFlowEvidenceField 'cli-reported-version' 'cli_reported_version')
gh_tag=$(auditFlowEvidenceField 'http-json-upstream-version' 'http_json_extracted')
compare_cli_to_github_semver=$(readManifestScalarLine "${_manifest}" compare_cli_to_github_semver)
if [ "${compare_cli_to_github_semver}" = "true" ]; then
    auditFlowRunModuleStem upstream-semver-drift "${cli_ver}" "${gh_tag}" || exit 1
else
    auditFlowAppendSkippedFromModuleStem upstream-semver-drift \
        "compare_cli_to_github_semver is not true in shellcheck/audit.manifest.yaml; skipping CLI vs GitHub release compare (typical for apt-installed shellcheck)." || exit 1
fi

########################################################
# End Audit Flow - Return result
#
auditFlowEmitMeasurementJson
exit 0
