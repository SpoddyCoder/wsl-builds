#!/usr/bin/env bash
# shellcheck shell=bash
# Resolve catalogue module paths under src/review/audit-checks/ (kebab-case stem, no .sh).
#
# Requires REPO_ROOT (repo root). Sourced only.

# Args: stem (e.g. cli-reported-version)
# Prints: absolute path to src/review/audit-checks/<stem>.sh
# Returns non-zero if the file is missing (unknown stem or path typo).
auditCheckModulePath() {
    local stem="${1:?auditCheckModulePath: module stem required}"
    local path
    path=$(printf '%s/src/review/audit-checks/%s.sh' "${REPO_ROOT:?REPO_ROOT required}" "${stem}")
    if [ ! -f "${path}" ]; then
        printf '%s\n' "auditCheckModulePath: unknown catalogue stem or missing module '${stem}' (expected file: ${path})" >&2
        return 1
    fi
    printf '%s' "${path}"
}
