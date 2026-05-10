#!/usr/bin/env bash
# shellcheck shell=bash
# Resolve check module paths under src/review/audit-checks/ (kebab-case check module name, no .sh).
#
# Requires REPO_ROOT (repo root). Sourced only.

# Args: check module name (e.g. cli-reported-version)
# Prints: absolute path to src/review/audit-checks/<check-module-name>.sh
# Returns non-zero if the file is missing (unknown check module name or path typo).
auditCheckModulePath() {
    local check_module_name="${1:?auditCheckModulePath: check module name required}"
    local path
    path=$(printf '%s/src/review/audit-checks/%s.sh' "${REPO_ROOT:?REPO_ROOT required}" "${check_module_name}")
    if [ ! -f "${path}" ]; then
        printf '%s\n' "auditCheckModulePath: unknown check module name or missing module '${check_module_name}' (expected file: ${path})" >&2
        return 1
    fi
    printf '%s' "${path}"
}
