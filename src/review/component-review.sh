#!/usr/bin/env bash
# Component review (spec Phase 1): invoke <slug>_audit.sh, merge runner fields, validate merged JSON,
# persist validated merged JSON to <slug>_review.result.json.
set -euo pipefail

# shellcheck source=runner-common.sh
source "${BASH_SOURCE[0]%/*}/runner-common.sh"

printComponentReviewUsage() {
    printf '%s\n' "Usage: ${RUNNER_BASENAME:-component-review.sh} <build-directory-name> <canonical-component-token>" >&2
    printf '%s\n' "Example: ./src/review/component-review.sh dev-js node" >&2
}

RUNNER_BASENAME=$(basename "${BASH_SOURCE[0]}")
exportRepoRootFromRunnerPath "${BASH_SOURCE[0]}"

# shellcheck source=src/print.sh
source "${REVIEW_REPO_ROOT}/src/print.sh"

WSL_BUILDS_USER_CONF="${HOME}/.wsl-builds.conf"
if [ -n "${WSL_BUILDS_CONF:-}" ]; then
    if [ ! -r "${WSL_BUILDS_CONF}" ]; then
        printError "WSL_BUILDS_CONF is set but is not readable: ${WSL_BUILDS_CONF}"
        exit 1
    fi
    # shellcheck source=wsl-builds.conf.example
    source "${WSL_BUILDS_CONF}"
    printInfo "Using: ${WSL_BUILDS_CONF}"
else
    if [ ! -r "${WSL_BUILDS_USER_CONF}" ]; then
        printError "No wsl-builds.conf found (set WSL_BUILDS_CONF or create ~/.wsl-builds.conf). Run ./configure.sh"
        exit 1
    fi
    # shellcheck source=wsl-builds.conf.example
    source "${WSL_BUILDS_USER_CONF}"
    printInfo "Using: ${WSL_BUILDS_USER_CONF}"
fi

# shellcheck source=src/builds-root.sh
source "${REVIEW_REPO_ROOT}/src/builds-root.sh"
resolveBuildsRootFromRepoRoot "${REVIEW_REPO_ROOT}" || exit 1

if ! command -v jq >/dev/null 2>&1; then
    printError "jq is required for component-review.sh. Install jq and see CONTRIBUTING.md (Automated builds review tooling)."
    exit 1
fi

# shellcheck source=merged-result-validation.sh
source "${BASH_SOURCE[0]%/*}/merged-result-validation.sh"

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

review_completed_ts=$(utcIso8601TimestampZ)
merged_json=$(jq -cn \
    --argjson audit "${audit_json}" \
    --arg build "${build_dir_name}" \
    --arg comp "${canonical_token}" \
    --arg ts "${review_completed_ts}" \
    '$audit | .build = $build | .component = $comp | .review_completed = $ts') \
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

merged_summary=$(jq -r '.summary // empty' <<<"${merged_json}")
if [ -n "${merged_summary}" ]; then
    printInfo "${merged_summary}"
fi

exit 0
