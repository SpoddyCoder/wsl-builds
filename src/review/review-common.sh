# Shared review primitives: repo layout for runners, CSV token ↔ on-disk filenames.
# Behaviour matches src/install-dispatch.sh (hyphen → underscore in script basenames only).
# Spec: "Component enumeration (v1): dispatch-aligned", "Paths and filenames (v1)".

# Resolve repository root from a review runner script path (a *.sh file directly under
# src/review/). Sets and exports REVIEW_REPO_ROOT for child processes.
#
# Usage (from src/review/component-review.sh after this file is sourced):
#   # shellcheck source=review-common.sh
#   source "${BASH_SOURCE[0]%/*}/review-common.sh"
#   reviewInitRepoRootFromRunnerScript "${BASH_SOURCE[0]}"
reviewInitRepoRootFromRunnerScript() {
    local runnerPath="${1:?runner script path required}"
    REVIEW_REPO_ROOT="$(cd "$(dirname "${runnerPath}")/../.." && pwd)" || return 1
    export REVIEW_REPO_ROOT
}

# On-disk fragment for install_<fragment>.sh and audit_<fragment>.sh (not for review_* files).
# Same rule as dispatch_install_component_slug in src/install-dispatch.sh.
canonicalCsvTokenToOnDiskSlug() {
    local token="${1:?canonical CSV component token required}"
    printf '%s\n' "${token//-/_}"
}

# Default builds directory under the repo only (<repo>/builds). For runtime resolution including
# EXTERNAL_BUILDS_ROOT, callers source src/builds-root.sh after user conf + src/print.sh (same as ./wsl-builder.sh).
reviewDefaultBuildsDirUnderRepo() {
    local repoRoot="${1:?repository root required}"
    printf '%s/builds\n' "${repoRoot%/}"
}

# ISO 8601 UTC with seconds and trailing Z (v1 review_completed).
reviewUtcTimestampIsoSecondsZ() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

reviewPathForInstallScript() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/install_%s.sh\n' "${buildDir%/}" "${slug}"
}

reviewPathForAuditScript() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/audit_%s.sh\n' "${buildDir%/}" "${slug}"
}

# Maintainer manifest uses the canonical token in the filename (hyphens preserved).
reviewPathForReviewManifest() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    printf '%s/review_%s.yaml\n' "${buildDir%/}" "${token}"
}

reviewPathForReviewResult() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    printf '%s/review_%s.result.json\n' "${buildDir%/}" "${token}"
}
