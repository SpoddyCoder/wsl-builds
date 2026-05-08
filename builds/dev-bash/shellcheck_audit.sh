#!/usr/bin/env bash
# Advisory review for the shellcheck component (dev-bash build).
#
# Measurement: all six v1 catalogue modules under src/review/audit-checks/ (signal-first):
#   cli-reported-version, deb-installed-version, installer-validated-staleness,
#   http-json-upstream-version, upstream-exact-match, upstream-semver-drift.
# checks[].audit_check_id values are the module basename (.sh stripped) via auditCheckIdFromModulePath;
# pass a second suffix argument to that helper only when one module runs twice in the same audit.
# Folded via measurement-bundle.sh. Concerns policy views are computed by component-review.sh.
#
# Stdout: one JSON object line (measurement envelope for component-review.sh). Stderr: diagnostics only.
# Does not install packages. Requires jq; HTTP check requires curl (see CONTRIBUTING.md).

set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_root="$(cd "${_script_dir}/../.." && pwd)"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/measurement-bundle.sh"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/read-manifest-scalar.sh"
# shellcheck source=/dev/null
source "${_repo_root}/src/review/audit-check-helpers/get-audit-check-id.sh"

readonly _manifest="${_script_dir}/shellcheck_review.yaml"

readonly requiredCheckIdsJson='["cli-reported-version","deb-installed-version","installer-validated-staleness","upstream-exact-match"]'
readonly _emptyMeasurementBundle='{"checks":[],"evidence":{}}'
readonly _cliCheckModule="${_repo_root}/src/review/audit-checks/cli-reported-version.sh"
readonly _debCheckModule="${_repo_root}/src/review/audit-checks/deb-installed-version.sh"
readonly _stalenessCheckModule="${_repo_root}/src/review/audit-checks/installer-validated-staleness.sh"
readonly _httpJsonModule="${_repo_root}/src/review/audit-checks/http-json-upstream-version.sh"
readonly _upstreamExactModule="${_repo_root}/src/review/audit-checks/upstream-exact-match.sh"
readonly _semverModule="${_repo_root}/src/review/audit-checks/upstream-semver-drift.sh"
readonly _github_latest_url='https://api.github.com/repos/koalaman/shellcheck/releases/latest'

_idCli=$(auditCheckIdFromModulePath "${_cliCheckModule}") || exit 1
_idDeb=$(auditCheckIdFromModulePath "${_debCheckModule}") || exit 1
_idStaleness=$(auditCheckIdFromModulePath "${_stalenessCheckModule}") || exit 1
_idHttp=$(auditCheckIdFromModulePath "${_httpJsonModule}") || exit 1
_idExact=$(auditCheckIdFromModulePath "${_upstreamExactModule}") || exit 1
_idSemver=$(auditCheckIdFromModulePath "${_semverModule}") || exit 1
readonly _idCli _idDeb _idStaleness _idHttp _idExact _idSemver

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "shellcheck_audit.sh: jq is required to emit JSON; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

emitMeasurementJson() {
    local checks_json="$1"
    local evidence_json="$2"
    jq -cn \
        --argjson checks "${checks_json}" \
        --argjson evidence "${evidence_json}" \
        --argjson rq "${requiredCheckIdsJson}" \
        '{ component_reviewer_version: 1, checks: $checks, evidence: $evidence, required_check_ids: $rq }'
}

installer_validated=$(readManifestScalarLine "${_manifest}" installer_validated)
installer_staleness_max_days=$(readManifestScalarLine "${_manifest}" installer_staleness_max_days)
last_known_upstream=$(readManifestScalarLine "${_manifest}" last_known_upstream)
if [ -z "${installer_staleness_max_days}" ]; then
    installer_staleness_max_days='90'
fi

merged="${_emptyMeasurementBundle}"

mergeEnvelopeLine() {
    local envelope_line="$1"
    local bundle
    bundle=$(measurementBundleFromCheckEnvelopeLine "${envelope_line}") || return 1
    merged=$(mergeMeasurementBundles "${merged}" "${bundle}") || return 1
}

mergeEnvelopeLine "$(bash "${_cliCheckModule}" "${_idCli}" shellcheck)" || {
    printf '%s\n' 'shellcheck_audit.sh: cli-reported-version.sh failed' >&2
    exit 1
}
mergeEnvelopeLine "$(bash "${_debCheckModule}" "${_idDeb}" shellcheck)" || {
    printf '%s\n' 'shellcheck_audit.sh: deb-installed-version.sh failed' >&2
    exit 1
}
mergeEnvelopeLine "$(bash "${_stalenessCheckModule}" "${_idStaleness}" "${installer_validated}" "${installer_staleness_max_days}")" || {
    printf '%s\n' 'shellcheck_audit.sh: installer-validated-staleness.sh failed' >&2
    exit 1
}

mergeEnvelopeLine "$(bash "${_httpJsonModule}" "${_idHttp}" "${_github_latest_url}" '.tag_name')" || {
    printf '%s\n' 'shellcheck_audit.sh: http-json-upstream-version.sh failed' >&2
    exit 1
}

deb_ver=$(printf '%s\n' "${merged}" | jq -r '.evidence.deb_installed_version // empty')
mergeEnvelopeLine "$(bash "${_upstreamExactModule}" "${_idExact}" "${last_known_upstream}" "${deb_ver}")" || {
    printf '%s\n' 'shellcheck_audit.sh: upstream-exact-match.sh failed' >&2
    exit 1
}

cli_ver=$(printf '%s\n' "${merged}" | jq -r '.evidence.cli_reported_version // empty')
gh_tag=$(printf '%s\n' "${merged}" | jq -r '.evidence.http_json_extracted // empty')
compare_cli_to_github_semver=$(readManifestScalarLine "${_manifest}" compare_cli_to_github_semver)
if [ "${compare_cli_to_github_semver}" = "true" ]; then
    mergeEnvelopeLine "$(bash "${_semverModule}" "${_idSemver}" "${cli_ver}" "${gh_tag}")" || {
        printf '%s\n' 'shellcheck_audit.sh: upstream-semver-drift.sh failed' >&2
        exit 1
    }
else
    mergeEnvelopeLine "$(jq -cn \
        --arg audit_check_id "${_idSemver}" \
        '{
             check: {
                 audit_check_id: $audit_check_id,
                 outcome: "skipped",
                 detail: "compare_cli_to_github_semver is not true in shellcheck_review.yaml; skipping CLI vs GitHub release compare (typical for apt-installed shellcheck)."
             },
             evidence: {}
         }')"
fi

checks_json=$(printf '%s\n' "${merged}" | jq -c '.checks')
evidence_json=$(printf '%s\n' "${merged}" | jq -c '.evidence')
emitMeasurementJson "${checks_json}" "${evidence_json}"
exit 0
