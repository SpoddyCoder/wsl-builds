#!/usr/bin/env bash
# shellcheck shell=bash
# Derive checks[].audit_check_id values from audit-check module paths (catalogue filenames under
# src/review/audit-checks/). Sourced only.

# Args: path_to_module.sh [suffix]
# Prints: basename without .sh, or <check-module-name>_<suffix> when suffix is non-empty (rare second use of same module).
auditCheckIdFromModulePath() {
    local module_path="${1:?audit-check module path required}"
    local suffix="${2:-}"
    local base="${module_path##*/}"
    local check_module_name="${base%.sh}"
    if [ -z "${check_module_name}" ]; then
        printf '%s\n' "auditCheckIdFromModulePath: empty check module name from path ${module_path}" >&2
        return 1
    fi
    if [ -n "${suffix}" ]; then
        printf '%s_%s' "${check_module_name}" "${suffix}"
    else
        printf '%s' "${check_module_name}"
    fi
}
