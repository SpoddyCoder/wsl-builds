#!/usr/bin/env bash
# shellcheck shell=bash
# Declarative flow helpers for <slug>/audit.sh composition.
#
# Keeps audits focused on "what checks to run" while centralizing:
# - jq requirement checks
# - audit_check_id derivation from module path
# - check row append to checks[]
# - evidence extraction from prior checks
# - final measurement envelope emit
#
# Source this helper from builds/<build>/<slug>/audit.sh.

# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/measurement-bundle.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/audit-check-module-path.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/src/review/audit-check-helpers/get-audit-check-id.sh"

AUDIT_FLOW_CONTEXT="${AUDIT_FLOW_CONTEXT:-audit.sh}"
AUDIT_FLOW_CHECKS_JSON='[]'
AUDIT_FLOW_REQUIRED_CHECK_IDS_JSON='[]'

auditFlowInit() {
    local context_name="${1:?auditFlowInit: context name required}"
    local required_ids_json="${2:?auditFlowInit: required_check_ids JSON array required}"
    AUDIT_FLOW_CONTEXT="${context_name}"
    AUDIT_FLOW_REQUIRED_CHECK_IDS_JSON="${required_ids_json}"
    AUDIT_FLOW_CHECKS_JSON='[]'
    if ! command -v jq >/dev/null 2>&1; then
        printf '%s\n' "${AUDIT_FLOW_CONTEXT}: jq is required to emit JSON; see CONTRIBUTING.md (Automated builds review tooling)." >&2
        return 1
    fi
}

auditFlowAppendCheckLine() {
    local check_line="${1:?auditFlowAppendCheckLine: check line required}"
    AUDIT_FLOW_CHECKS_JSON=$(appendCheckLineToChecksArray "${check_line}" "${AUDIT_FLOW_CHECKS_JSON}") || return 1
}

auditFlowRunModule() {
    local module_path="${1:?auditFlowRunModule: module path required}"
    shift
    local audit_check_id
    audit_check_id=$(auditCheckIdFromModulePath "${module_path}") || return 1
    local check_line
    check_line=$(bash "${module_path}" "${audit_check_id}" "$@") || {
        printf '%s\n' "${AUDIT_FLOW_CONTEXT}: ${module_path##*/} failed" >&2
        return 1
    }
    auditFlowAppendCheckLine "${check_line}"
}

auditFlowRunModuleWithSuffix() {
    local module_path="${1:?auditFlowRunModuleWithSuffix: module path required}"
    local id_suffix="${2:?auditFlowRunModuleWithSuffix: id suffix required}"
    shift 2
    local audit_check_id
    audit_check_id=$(auditCheckIdFromModulePath "${module_path}" "${id_suffix}") || return 1
    local check_line
    check_line=$(bash "${module_path}" "${audit_check_id}" "$@") || {
        printf '%s\n' "${AUDIT_FLOW_CONTEXT}: ${module_path##*/} failed" >&2
        return 1
    }
    auditFlowAppendCheckLine "${check_line}"
}

auditFlowRunCheckModuleName() {
    local check_module_name="${1:?auditFlowRunCheckModuleName: check module name required}"
    shift
    local module_path
    module_path=$(auditCheckModulePath "${check_module_name}") || return 1
    auditFlowRunModule "${module_path}" "$@"
}

auditFlowRunCheckModuleNameWithSuffix() {
    local check_module_name="${1:?auditFlowRunCheckModuleNameWithSuffix: check module name required}"
    local id_suffix="${2:?auditFlowRunCheckModuleNameWithSuffix: id suffix required}"
    shift 2
    local module_path
    module_path=$(auditCheckModulePath "${check_module_name}") || return 1
    auditFlowRunModuleWithSuffix "${module_path}" "${id_suffix}" "$@"
}

auditFlowAppendSkippedFromModule() {
    local module_path="${1:?auditFlowAppendSkippedFromModule: module path required}"
    local detail="${2:?auditFlowAppendSkippedFromModule: detail required}"
    local audit_check_id
    audit_check_id=$(auditCheckIdFromModulePath "${module_path}") || return 1
    auditFlowAppendCheckLine "$(jq -cn \
        --arg audit_check_id "${audit_check_id}" \
        --arg detail "${detail}" \
        '{ audit_check_id: $audit_check_id, outcome: "skipped", detail: $detail }')"
}

auditFlowAppendSkippedFromCheckModuleName() {
    local check_module_name="${1:?auditFlowAppendSkippedFromCheckModuleName: check module name required}"
    local detail="${2:?auditFlowAppendSkippedFromCheckModuleName: detail required}"
    local module_path
    module_path=$(auditCheckModulePath "${check_module_name}") || return 1
    auditFlowAppendSkippedFromModule "${module_path}" "${detail}"
}

auditFlowEvidenceField() {
    local audit_check_id="${1:?auditFlowEvidenceField: audit_check_id required}"
    local evidence_key="${2:?auditFlowEvidenceField: evidence key required}"
    jq -r \
        --arg audit_check_id "${audit_check_id}" \
        --arg evidence_key "${evidence_key}" \
        '.[] | select(.audit_check_id==$audit_check_id) | .evidence[$evidence_key] // empty' \
        <<<"${AUDIT_FLOW_CHECKS_JSON}"
}

auditFlowEmitMeasurementJson() {
    jq -cn \
        --argjson checks "${AUDIT_FLOW_CHECKS_JSON}" \
        --argjson required_check_ids "${AUDIT_FLOW_REQUIRED_CHECK_IDS_JSON}" \
        '{ component_reviewer_version: 1, checks: $checks, required_check_ids: $required_check_ids }'
}
