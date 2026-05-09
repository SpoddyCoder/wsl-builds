# Component review runner implementation (sourced from review/component-review.sh).
# Requires: REPO_ROOT, RUNNER_BASENAME, print helpers, loadWslBuildsConfOrExit,
# resolveBuildsRootFromRepoRoot, jq on PATH.

# shellcheck source=runner-common.sh
source "${BASH_SOURCE[0]%/*}/runner-common.sh"

# shellcheck source=merged-result-validation.sh
source "${BASH_SOURCE[0]%/*}/merged-result-validation.sh"
# shellcheck source=checks-rollup.sh
source "${BASH_SOURCE[0]%/*}/checks-rollup.sh"

printComponentReviewUsage() {
    printf '%s\n' "Usage: ${RUNNER_BASENAME:-component-review.sh} <build-directory-name> <canonical-component-token>" >&2
    printf '%s\n' "Example: ./review/component-review.sh dev-js node" >&2
}

componentReviewMain() {
    if [ "${#}" -ne 2 ]; then
        printComponentReviewUsage
        exit 1
    fi

    local build_dir_name="${1}"
    local canonical_token="${2}"
    local BUILD_DIR="${BUILDS_ROOT}/${build_dir_name}"

    if [ ! -d "${BUILD_DIR}" ] || [ ! -f "${BUILD_DIR}/conf.sh" ]; then
        printError "Build directory '${build_dir_name}' not found under ${BUILDS_ROOT} (expected conf.sh)."
        exit 1
    fi

    local audit_script
    audit_script=$(pathForAuditScript "${BUILD_DIR}" "${canonical_token}") || exit 1
    if [ ! -f "${audit_script}" ]; then
        printError "No audit script for token '${canonical_token}': ${audit_script}"
        exit 1
    fi

    local audit_stdout audit_stderr
    audit_stdout=$(mktemp)
    audit_stderr=$(mktemp)
    trap 'rm -f "${audit_stdout}" "${audit_stderr}"' EXIT

    set +e
    bash "${audit_script}" >"${audit_stdout}" 2>"${audit_stderr}"
    local audit_ec=${?}
    set -e

    if [ -s "${audit_stderr}" ]; then
        cat "${audit_stderr}" >&2
    fi

    if [ "${audit_ec}" -ne 0 ]; then
        printError "audit script exited ${audit_ec}: ${audit_script}"
        exit 1
    fi

    local stdout_fd
    exec {stdout_fd}<"${audit_stdout}"
    local json_line _extra_line
    if ! read -r json_line <&"${stdout_fd}"; then
        printError "audit stdout is empty (expected one JSON object line): ${audit_script}"
        exit 1
    fi
    if read -r _extra_line <&"${stdout_fd}"; then
        printError "audit stdout must be exactly one logical line (got extra output): ${audit_script}"
        exit 1
    fi
    exec {stdout_fd}<&-

    local audit_json
    if ! audit_json=$(jq -ec . <<<"${json_line}" 2>/dev/null); then
        printError "audit stdout is not parseable as one JSON object: ${audit_script}"
        exit 1
    fi

    validateAuditMeasurementJson "${audit_json}" || exit 1

    local checks_for_concerns required_ids_for_concerns policy_for_concerns concerns_json
    checks_for_concerns=$(jq -ec '.checks' <<<"${audit_json}") || exit 1
    required_ids_for_concerns=$(jq -ec '.required_check_ids' <<<"${audit_json}") || exit 1
    policy_for_concerns=$(jq -ec '.custom_issue_policy // {}' <<<"${audit_json}") || exit 1
    concerns_json=$(emitConcernsFromChecks "${checks_for_concerns}" "${required_ids_for_concerns}" "${policy_for_concerns}") || exit 1

    local review_completed_ts merged_json
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

    local result_path result_tmp
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
}
