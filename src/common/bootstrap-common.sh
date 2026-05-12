# Shared bootstrap helpers for top-level entrypoints (strict mode lives in callers).
#
# Call order (when user config + BUILDS_ROOT are needed):
#   1. Source this file (path must be resolvable without REPO_ROOT, e.g. "$(cd "$(dirname "$0")" && pwd)/src/common/bootstrap-common.sh").
#   2. resolveRepoRoot* / resolveRepoRootFromSourcePath — sets REPO_ROOT (no print helpers required).
#   3. Source "${REPO_ROOT}/src/common/print.sh" before any function here that uses printError / printInfo.
#   4. loadWslBuildsConfOrExit — after print.sh.
#   5. Source "${REPO_ROOT}/src/builder/builds-root.sh" and resolveBuildsRootFromRepoRoot "${REPO_ROOT}" when BUILDS_ROOT / EXTERNAL_BUILDS_ROOT apply; for ./wsl-stacker.sh, source "${REPO_ROOT}/src/stacker/stacks-root.sh" and resolveStacksRootFromRepoRoot "${REPO_ROOT}" when STACKS_ROOT / EXTERNAL_STACKS_ROOT apply.
#
# Do not add set -euo pipefail in this file; entrypoints own shell options.

# Resolve repository root: directory containing the given script path, then optional relative path
# (e.g. ".." for test/run-tests.sh, "../.." for src/review runners and test/docker/run-bats.sh).
resolveRepoRootFromSourcePath() {
    local scriptPath="${1:?script path required}"
    local rel="${2:-}"
    if [ -n "${rel}" ]; then
        REPO_ROOT="$(cd "$(dirname "${scriptPath}")/${rel}" && pwd)" || return 1
    else
        REPO_ROOT="$(cd "$(dirname "${scriptPath}")" && pwd)" || return 1
    fi
}

# wsl-builder.sh: use the path the user invoked ($0) so behaviour matches historical resolution.
resolveRepoRootFromBuilderPath() {
    local invocationPath="${1:?invocation path required}"
    REPO_ROOT="$(cd "$(dirname "${invocationPath}")" && pwd)" || return 1
}

# builds/<build>/<slug>/audit.sh — three parents up from the component directory to repo root.
resolveRepoRootFromAuditScript() {
    local auditScriptPath="${1:?audit script path required}"
    local scriptDir
    scriptDir="$(cd "$(dirname "${auditScriptPath}")" && pwd)" || return 1
    REPO_ROOT="$(cd "${scriptDir}/../../.." && pwd)" || return 1
    export REPO_ROOT
}

# Announce the loaded config path once per invocation chain (exported for child entrypoints).
printWslBuildsConfPathOnce() {
    local confPath="${1:?}"
    if [ -n "${WSL_BUILDS_CONF_INFO_PRINTED:-}" ]; then
        return 0
    fi
    export WSL_BUILDS_CONF_INFO_PRINTED=1
    printInfo "Using: ${confPath}"
}

# Single implementation for WSL_BUILDS_CONF vs ~/.wsl-builds.conf. Caller must source src/common/print.sh first.
loadWslBuildsConfOrExit() {
    local userConf="${HOME}/.wsl-builds.conf"
    if [ -n "${WSL_BUILDS_CONF:-}" ]; then
        if [ ! -r "${WSL_BUILDS_CONF}" ]; then
            printError "WSL_BUILDS_CONF is set but not readable: ${WSL_BUILDS_CONF}"
            exit 1
        fi
        # shellcheck source=wsl-builds.conf.example
        source "${WSL_BUILDS_CONF}"
        printWslBuildsConfPathOnce "${WSL_BUILDS_CONF}"
        return 0
    fi
    if [ ! -r "${userConf}" ]; then
        printError "No wsl-builds.conf found (set WSL_BUILDS_CONF or create ~/.wsl-builds.conf). Run ./configure.sh"
        exit 1
    fi
    # shellcheck source=wsl-builds.conf.example
    source "${userConf}"
    printWslBuildsConfPathOnce "${userConf}"
}
