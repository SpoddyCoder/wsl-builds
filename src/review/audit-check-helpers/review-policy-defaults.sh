#!/usr/bin/env bash
# shellcheck shell=bash
# Repo-level review policy defaults (sourced by builds/<build>/<slug>/audit.sh).
# Requires REPO_ROOT (repo root) before calling resolveInstallerStalenessMaxDays.

# shellcheck source=read-manifest-scalar.sh
source "${BASH_SOURCE[0]%/*}/read-manifest-scalar.sh"

readonly REVIEW_POLICY_YAML_REL_PATH='review/review-policy.yaml'
readonly FALLBACK_INSTALLER_STALENESS_MAX_DAYS='90'

# Args: path_to_component_audit.manifest.yaml
# Prints resolved max-age days: manifest key, else review/review-policy.yaml, else FALLBACK_*.
resolveInstallerStalenessMaxDays() {
    local manifest="${1:?manifest path required}"
    local from_manifest from_policy
    from_manifest=$(readManifestScalarLine "${manifest}" installer_staleness_max_days)
    if [ -n "${from_manifest}" ]; then
        printf '%s' "${from_manifest}"
        return 0
    fi
    local policy="${REPO_ROOT:?REPO_ROOT required}/${REVIEW_POLICY_YAML_REL_PATH}"
    from_policy=$(readManifestScalarLine "${policy}" installer_staleness_max_days)
    if [ -n "${from_policy}" ]; then
        printf '%s' "${from_policy}"
        return 0
    fi
    printf '%s' "${FALLBACK_INSTALLER_STALENESS_MAX_DAYS}"
}
