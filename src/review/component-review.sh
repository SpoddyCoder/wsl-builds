#!/usr/bin/env bash
# Component review (spec Phase 1): invoke <slug>/audit.sh, merge runner fields, validate merged JSON,
# persist validated merged JSON to <slug>/review.result.json.
set -euo pipefail

# shellcheck source=runner-common.sh
source "${BASH_SOURCE[0]%/*}/runner-common.sh"

printComponentReviewUsage() {
    printf '%s\n' "Usage: ${RUNNER_BASENAME:-component-review.sh} <build-directory-name> <canonical-component-token>" >&2
    printf '%s\n' "Example: ./src/review/component-review.sh dev-js node" >&2
}

RUNNER_BASENAME=$(basename "${BASH_SOURCE[0]}")
exportRepoRootFromRunnerPath "${BASH_SOURCE[0]}"

# shellcheck source=../common/print.sh
source "${REPO_ROOT}/src/common/print.sh"

loadWslBuildsConfOrExit

# shellcheck source=../builder/builds-root.sh
source "${REPO_ROOT}/src/builder/builds-root.sh"
resolveBuildsRootFromRepoRoot "${REPO_ROOT}" || exit 1

if ! command -v jq >/dev/null 2>&1; then
    printError "jq is required for component-review.sh. Install jq and see CONTRIBUTING.md (Automated builds review tooling)."
    exit 1
fi

# shellcheck source=merged-result-validation.sh
source "${BASH_SOURCE[0]%/*}/merged-result-validation.sh"
# shellcheck source=checks-rollup.sh
source "${BASH_SOURCE[0]%/*}/checks-rollup.sh"

if [ "${#}" -ne 2 ]; then
    printComponentReviewUsage
    exit 1
fi

build_dir_name="${1}"
canonical_token="${2}"
BUILD_DIR="${BUILDS_ROOT}/${build_dir_name}"

if [ ! -d "${BUILD_DIR}" ] || [ ! -f "${BUILD_DIR}/conf.sh" ]; then
    printError "Build directory '${build_dir_name}' not found under ${BUILDS_ROOT} (expected conf.sh)."
    exit 1
fi

audit_script=$(pathForAuditScript "${BUILD_DIR}" "${canonical_token}") || exit 1
if [ ! -f "${audit_script}" ]; then
    printError "No audit script for token '${canonical_token}': ${audit_script}"
    exit 1
fi

audit_stdout=$(mktemp)
audit_stderr=$(mktemp)
trap 'rm -f "${audit_stdout}" "${audit_stderr}"' EXIT

set +e
bash "${audit_script}" >"${audit_stdout}" 2>"${audit_stderr}"
audit_ec=${?}
set -e

if [ -s "${audit_stderr}" ]; then
    cat "${audit_stderr}" >&2
fi

if [ "${audit_ec}" -ne 0 ]; then
    printError "audit script exited ${audit_ec}: ${audit_script}"
    exit 1
fi

exec {stdout_fd}<"${audit_stdout}"
if ! read -r json_line <&"${stdout_fd}"; then
    printError "audit stdout is empty (expected one JSON object line): ${audit_script}"
    exit 1
fi
if read -r _extra_line <&"${stdout_fd}"; then
    printError "audit stdout must be exactly one logical line (got extra output): ${audit_script}"
    exit 1
fi
exec {stdout_fd}<&-

if ! audit_json=$(jq -ec . <<<"${json_line}" 2>/dev/null); then
    printError "audit stdout is not parseable as one JSON object: ${audit_script}"
    exit 1
fi

validateAuditMeasurementJson "${audit_json}" || exit 1

checks_for_concerns=$(jq -ec '.checks' <<<"${audit_json}") || exit 1
required_ids_for_concerns=$(jq -ec '.required_check_ids' <<<"${audit_json}") || exit 1
policy_for_concerns=$(jq -ec '.custom_issue_policy // {}' <<<"${audit_json}") || exit 1
concerns_json=$(emitConcernsFromChecks "${checks_for_concerns}" "${required_ids_for_concerns}" "${policy_for_concerns}") || exit 1

review_completed_ts=$(utcIso8601TimestampZ)
merged_json=$(jq -cn \
    --argjson audit "$(jq -ec 'del(.required_check_ids, .custom_issue_policy)' <<<"${audit_json}")" \
    --arg build "${build_dir_name}" \
    --arg comp "${canonical_token}" \
    --arg ts "${review_completed_ts}" \
    --argjson concerns "${concerns_json}" \
    '$audit | .build = $build | .component = $comp | .review_completed = $ts | .concerns = $concerns') \
    || {
        printError "failed to merge runner fields into audit JSON"
        exit 1
    }

validateMergedResultJson "${merged_json}" || exit 1

result_path=$(pathForReviewResultJson "${BUILD_DIR}" "${canonical_token}") || exit 1
result_tmp="${result_path}.tmp.$$"
if ! jq . <<<"${merged_json}" >"${result_tmp}"; then
    rm -f "${result_tmp}"
    printError "failed to write temporary review result: ${result_path}"
    exit 1
fi
if ! mv -f "${result_tmp}" "${result_path}"; then
    rm -f "${result_tmp}"
    printError "failed to persist review result: ${result_path}"
    exit 1
fi

printInfo "Wrote ${result_path}"

exit 0
