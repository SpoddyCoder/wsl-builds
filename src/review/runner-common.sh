# Shared review primitives: repo layout for runners, CSV token ↔ on-disk filenames.
# Behaviour matches src/install-dispatch.sh (hyphen → underscore in script basenames only).
# Spec: "Component enumeration (v1): dispatch-aligned", "Paths and filenames (v1)".

# Resolve repository root from a review runner script path (a *.sh file directly under
# src/review/). Sets and exports REVIEW_REPO_ROOT for child processes.
#
# Usage (from src/review/component-review.sh after this file is sourced):
#   # shellcheck source=runner-common.sh
#   source "${BASH_SOURCE[0]%/*}/runner-common.sh"
#   exportRepoRootFromRunnerPath "${BASH_SOURCE[0]}"
exportRepoRootFromRunnerPath() {
    local runnerPath="${1:?runner script path required}"
    REVIEW_REPO_ROOT="$(cd "$(dirname "${runnerPath}")/../.." && pwd)" || return 1
    export REVIEW_REPO_ROOT
}

# On-disk slug: same mapping as install_<slug>.sh in src/install-dispatch.sh (CSV hyphens → underscores).
# Used for install path helpers, audit script path (<slug>_audit.sh), and maintainer artefact names (<slug>_review.*).
canonicalCsvTokenToOnDiskSlug() {
    local token="${1:?canonical CSV component token required}"
    printf '%s\n' "${token//-/_}"
}

# Default builds directory under the repo only (<repo>/builds). For runtime resolution including
# EXTERNAL_BUILDS_ROOT, callers source src/builds-root.sh after user conf + src/print.sh (same as ./wsl-builder.sh).
defaultBuildsDirUnderRepo() {
    local repoRoot="${1:?repository root required}"
    printf '%s/builds\n' "${repoRoot%/}"
}

# ISO 8601 UTC with seconds and trailing Z (v1 review_completed).
utcIso8601TimestampZ() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

pathForInstallScript() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/install_%s.sh\n' "${buildDir%/}" "${slug}"
}

pathForAuditScript() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/%s_audit.sh\n' "${buildDir%/}" "${slug}"
}

# Maintainer manifest and persisted JSON use the same slug as install/audit basenames (not hyphenated CSV in filenames).
pathForMaintainerYaml() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/%s_review.yaml\n' "${buildDir%/}" "${slug}"
}

pathForReviewResultJson() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/%s_review.result.json\n' "${buildDir%/}" "${slug}"
}
