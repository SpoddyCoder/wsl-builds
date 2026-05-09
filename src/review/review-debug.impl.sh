# Maintainer debug harness implementation (sourced from review/review-debug.sh).
# Requires: REPO_ROOT, RUNNER_BASENAME, print helpers, jq on PATH for most modes.

# shellcheck source=runner-common.sh
source "${BASH_SOURCE[0]%/*}/runner-common.sh"

# shellcheck source=merged-result-validation.sh
source "${BASH_SOURCE[0]%/*}/merged-result-validation.sh"
# shellcheck source=checks-rollup.sh
source "${BASH_SOURCE[0]%/*}/checks-rollup.sh"
# shellcheck source=audit-check-helpers/audit-check-module-path.sh
source "${BASH_SOURCE[0]%/*}/audit-check-helpers/audit-check-module-path.sh"
# shellcheck source=audit-check-helpers/get-audit-check-id.sh
source "${BASH_SOURCE[0]%/*}/audit-check-helpers/get-audit-check-id.sh"

readonly DEFAULT_FIXTURE_BUILD='review-fixture'

printDebugUsage() {
    cat >&2 <<USAGE
Usage: ${RUNNER_BASENAME} <mode> [options]

Modes:
  run-check  --module <name>  [--args '<argv>']        [--json|--pretty]
  run-audit  --build <name>   --component <token>      [--show-concerns] [--json|--pretty]
  run-review --build <name>   --component <token>      [--json|--pretty]
  run-e2e   [--build <name>]  --component <token>      [--show-concerns] [--json|--pretty]
  --help

Defaults:
  run-e2e --build defaults to '${DEFAULT_FIXTURE_BUILD}'.
  --module is the catalogue stem under src/review/audit-checks/ (no path, no .sh).
  run-check always derives audit_check_id from --module via auditCheckIdFromModulePath.
  --args is split by shell word-splitting and passed after the derived check_id.

Legacy aliases (deprecated): check, audit, component, scenario.

Examples:
  ${RUNNER_BASENAME} run-check  --module cli-reported-version --args 'shellcheck'
  ${RUNNER_BASENAME} run-audit  --build review-fixture --component happy-path --pretty
  ${RUNNER_BASENAME} run-review --build review-fixture --component happy-path --pretty
  ${RUNNER_BASENAME} run-e2e    --component issue-routed --show-concerns --pretty
USAGE
}

requireJqOrExit() {
    if ! command -v jq >/dev/null 2>&1; then
        printError "jq is required for ${RUNNER_BASENAME}. Install jq and see CONTRIBUTING.md (Automated builds review tooling)."
        exit 1
    fi
}

emitJsonPayload() {
    local payload="${1:-}"
    local mode="${2:-raw}"
    if [ -z "${payload}" ]; then
        return 0
    fi
    case "${mode}" in
        pretty)
            jq . <<<"${payload}"
            ;;
        json|raw|*)
            printf '%s\n' "${payload}"
            ;;
    esac
}

printConcernsSummary() {
    local concerns_json="$1"
    local mode="${2:-raw}"
    printInfo "Derived concerns:"
    emitJsonPayload "${concerns_json}" "${mode}"
}

resolveAuditScriptOrExit() {
    local build_dir="$1"
    local token="$2"
    local audit_script
    audit_script=$(pathForAuditScript "${build_dir}" "${token}") || exit 1
    if [ ! -f "${audit_script}" ]; then
        printError "No audit script for token '${token}': ${audit_script}"
        exit 1
    fi
    printf '%s' "${audit_script}"
}

resolveBuildDirOrExit() {
    local build_name="$1"
    local repo_builds="${REPO_ROOT}/builds/${build_name}"
    if [ ! -d "${repo_builds}" ] || [ ! -f "${repo_builds}/conf.sh" ]; then
        printError "Build directory '${build_name}' not found under ${REPO_ROOT}/builds (expected conf.sh)."
        exit 1
    fi
    printf '%s' "${repo_builds}"
}

runCheckMode() {
    local module_name=""
    local module_args=""
    local output_mode="raw"
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --module)
                module_name="${2:-}"
                shift 2
                ;;
            --args)
                module_args="${2:-}"
                shift 2
                ;;
            --json)
                output_mode="json"
                shift
                ;;
            --pretty)
                output_mode="pretty"
                shift
                ;;
            *)
                printError "run-check: unknown argument '$1'"
                printDebugUsage
                exit 1
                ;;
        esac
    done
    if [ -z "${module_name}" ]; then
        printError "run-check: --module is required"
        printDebugUsage
        exit 1
    fi
    local module_path
    module_path=$(auditCheckModulePath "${module_name}") || exit 1
    local derived_check_id
    derived_check_id=$(auditCheckIdFromModulePath "${module_path}") || exit 1
    local -a argv=("${derived_check_id}")
    if [ -n "${module_args}" ]; then
        # shellcheck disable=SC2206
        argv+=( ${module_args} )
    fi
    printInfo "Running check module: ${module_name}"
    set +e
    local module_stdout
    module_stdout=$(bash "${module_path}" "${argv[@]}")
    local module_ec=$?
    set -e
    emitJsonPayload "${module_stdout}" "${output_mode}"
    if [ "${module_ec}" -ne 0 ]; then
        printError "run-check: module exited ${module_ec}"
        exit "${module_ec}"
    fi
}

runAuditMode() {
    local build_name=""
    local token=""
    local output_mode="raw"
    local show_concerns="false"
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --build)
                build_name="${2:-}"
                shift 2
                ;;
            --component)
                token="${2:-}"
                shift 2
                ;;
            --json)
                output_mode="json"
                shift
                ;;
            --pretty)
                output_mode="pretty"
                shift
                ;;
            --show-concerns)
                show_concerns="true"
                shift
                ;;
            *)
                printError "run-audit: unknown argument '$1'"
                printDebugUsage
                exit 1
                ;;
        esac
    done
    if [ -z "${build_name}" ] || [ -z "${token}" ]; then
        printError "run-audit: --build and --component are required"
        printDebugUsage
        exit 1
    fi
    local build_dir
    build_dir=$(resolveBuildDirOrExit "${build_name}")
    local audit_script
    audit_script=$(resolveAuditScriptOrExit "${build_dir}" "${token}")
    printInfo "Running audit: ${audit_script}"
    set +e
    local audit_stdout
    audit_stdout=$(bash "${audit_script}")
    local audit_ec=$?
    set -e
    if [ "${audit_ec}" -ne 0 ]; then
        emitJsonPayload "${audit_stdout}" "${output_mode}"
        printError "run-audit: script exited ${audit_ec}"
        exit "${audit_ec}"
    fi
    local audit_json
    if ! audit_json=$(jq -ec . <<<"${audit_stdout}" 2>/dev/null); then
        emitJsonPayload "${audit_stdout}" "${output_mode}"
        printError "run-audit: stdout is not parseable as one JSON object"
        exit 1
    fi
    if ! validateAuditMeasurementJson "${audit_json}"; then
        emitJsonPayload "${audit_json}" "${output_mode}"
        exit 1
    fi
    emitJsonPayload "${audit_json}" "${output_mode}"
    if [ "${show_concerns}" = "true" ]; then
        local checks_json required_ids_json policy_json concerns_json
        checks_json=$(jq -ec '.checks' <<<"${audit_json}")
        required_ids_json=$(jq -ec '.required_check_ids' <<<"${audit_json}")
        policy_json=$(jq -ec '.custom_issue_policy // {}' <<<"${audit_json}")
        concerns_json=$(emitConcernsFromChecks "${checks_json}" "${required_ids_json}" "${policy_json}")
        printConcernsSummary "${concerns_json}" "${output_mode}"
    fi
}

runComponentMode() {
    local build_name=""
    local token=""
    local output_mode="raw"
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --build)
                build_name="${2:-}"
                shift 2
                ;;
            --component)
                token="${2:-}"
                shift 2
                ;;
            --json)
                output_mode="json"
                shift
                ;;
            --pretty)
                output_mode="pretty"
                shift
                ;;
            *)
                printError "run-review: unknown argument '$1'"
                printDebugUsage
                exit 1
                ;;
        esac
    done
    if [ -z "${build_name}" ] || [ -z "${token}" ]; then
        printError "run-review: --build and --component are required"
        printDebugUsage
        exit 1
    fi
    local build_dir
    build_dir=$(resolveBuildDirOrExit "${build_name}")
    printInfo "Running component-review for ${build_name}/${token}"
    set +e
    "${REPO_ROOT}/review/component-review.sh" "${build_name}" "${token}" >&2
    local runner_ec=$?
    set -e
    if [ "${runner_ec}" -ne 0 ]; then
        printError "run-review: component-review.sh exited ${runner_ec}"
        exit "${runner_ec}"
    fi
    local result_path
    result_path=$(pathForReviewResultJson "${build_dir}" "${token}") || exit 1
    if [ ! -f "${result_path}" ]; then
        printError "run-review: expected persisted result at ${result_path}"
        exit 1
    fi
    if [ "${output_mode}" = "pretty" ]; then
        jq . "${result_path}"
    else
        cat "${result_path}"
    fi
}

runScenarioMode() {
    local build_name="${DEFAULT_FIXTURE_BUILD}"
    local token=""
    local output_mode="raw"
    local show_concerns="false"
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --build)
                build_name="${2:-}"
                shift 2
                ;;
            --component)
                token="${2:-}"
                shift 2
                ;;
            --json)
                output_mode="json"
                shift
                ;;
            --pretty)
                output_mode="pretty"
                shift
                ;;
            --show-concerns)
                show_concerns="true"
                shift
                ;;
            *)
                printError "run-e2e: unknown argument '$1'"
                printDebugUsage
                exit 1
                ;;
        esac
    done
    if [ -z "${token}" ]; then
        printError "run-e2e: --component is required"
        printDebugUsage
        exit 1
    fi
    local -a audit_args=( --build "${build_name}" --component "${token}" )
    if [ "${show_concerns}" = "true" ]; then
        audit_args+=( --show-concerns )
    fi
    case "${output_mode}" in
        json) audit_args+=( --json ) ;;
        pretty) audit_args+=( --pretty ) ;;
    esac
    printInfo "run-e2e step 1/2: audit ${build_name}/${token}"
    runAuditMode "${audit_args[@]}"
    printInfo "run-e2e step 2/2: component-review ${build_name}/${token}"
    local -a component_args=( --build "${build_name}" --component "${token}" )
    case "${output_mode}" in
        json) component_args+=( --json ) ;;
        pretty) component_args+=( --pretty ) ;;
    esac
    runComponentMode "${component_args[@]}"
}

reviewDebugMain() {
    if [ "$#" -lt 1 ]; then
        printDebugUsage
        exit 1
    fi
    local mode="$1"
    shift
    case "${mode}" in
        --help|-h|help)
            printDebugUsage
            exit 0
            ;;
        run-check|check)
            requireJqOrExit
            runCheckMode "$@"
            ;;
        run-audit|audit)
            requireJqOrExit
            runAuditMode "$@"
            ;;
        run-review|component)
            requireJqOrExit
            runComponentMode "$@"
            ;;
        run-e2e|scenario)
            requireJqOrExit
            runScenarioMode "$@"
            ;;
        *)
            printError "unknown mode: ${mode}"
            printDebugUsage
            exit 1
            ;;
    esac
}
