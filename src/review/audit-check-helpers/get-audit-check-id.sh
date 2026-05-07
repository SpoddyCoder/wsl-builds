#!/usr/bin/env bash
# shellcheck shell=bash
# Derive checks[].audit_check_id values from audit-check module paths (catalogue filenames under
# src/review/audit-checks/). Sourced only.

# Args: path_to_module.sh [suffix]
# Prints: basename without .sh, or stem_suffix when suffix is non-empty (rare second use of same module).
auditCheckIdFromModulePath() {
    local module_path="${1:?audit-check module path required}"
    local suffix="${2:-}"
    local base="${module_path##*/}"
    local stem="${base%.sh}"
    if [ -z "${stem}" ]; then
        printf '%s\n' "auditCheckIdFromModulePath: empty stem from path ${module_path}" >&2
        return 1
    fi
    if [ -n "${suffix}" ]; then
        printf '%s_%s' "${stem}" "${suffix}"
    else
        printf '%s' "${stem}"
    fi
}
