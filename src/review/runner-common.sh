# Shared review primitives: repo layout for runners, CSV token ↔ on-disk filenames.
# Behaviour matches src/builder/install-dispatch.sh (hyphen → underscore in per-component path segments only).
# Spec: "Component enumeration (v1): dispatch-aligned", "Paths and filenames (v1)".

# shellcheck source=../common/bootstrap-common.sh
source "${BASH_SOURCE[0]%/*}/../common/bootstrap-common.sh"

# Resolve repository root from a path under src/review/ (e.g. *.impl.sh). Sets and exports
# REPO_ROOT for child processes. Review CLIs under review/ use resolveRepoRootFromSourcePath
# with ".." instead.
#
# Usage (from src/review/*.impl.sh after this file is sourced, when needed):
#   # shellcheck source=runner-common.sh
#   source "${BASH_SOURCE[0]%/*}/runner-common.sh"
#   exportRepoRootFromRunnerPath "${BASH_SOURCE[0]}"
exportRepoRootFromRunnerPath() {
    local runnerPath="${1:?runner script path required}"
    resolveRepoRootFromSourcePath "${runnerPath}" "../.." || return 1
    export REPO_ROOT
}

# On-disk slug: same mapping as per-component directories in src/builder/install-dispatch.sh (CSV hyphens → underscores).
# Used for install path helpers, audit script path (<slug>/audit.sh), and maintainer artefact paths
# (<slug>/audit.manifest.yaml, <slug>/review.result.json) under each builds/<build>/ directory.
canonicalCsvTokenToOnDiskSlug() {
    local token="${1:?canonical CSV component token required}"
    printf '%s\n' "${token//-/_}"
}

# Default builds directory under the repo only (<repo>/builds). For runtime resolution including
# EXTERNAL_BUILDS_ROOT, callers source src/builder/builds-root.sh after user conf + src/common/print.sh (same as ./wsl-builder.sh).
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
    printf '%s/%s/install.sh\n' "${buildDir%/}" "${slug}"
}

pathForAuditScript() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/%s/audit.sh\n' "${buildDir%/}" "${slug}"
}

# Maintainer manifest and persisted JSON live in the per-component review subdirectory
# builds/<build>/<slug>/ with short basenames (audit.manifest.yaml, review.result.json).
pathForMaintainerYaml() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/%s/audit.manifest.yaml\n' "${buildDir%/}" "${slug}"
}

pathForReviewResultJson() {
    local buildDir="${1:?build directory path required}"
    local token="${2:?canonical CSV token required}"
    local slug
    slug=$(canonicalCsvTokenToOnDiskSlug "${token}") || return 1
    printf '%s/%s/review.result.json\n' "${buildDir%/}" "${slug}"
}
