# shellcheck source=../common/print.sh
# Resolve BUILDS_ROOT after user wsl-builds.conf has been sourced (EXTERNAL_BUILDS_ROOT may be set).
# Shared by ./wsl-builder.sh and review/component-review.sh (via its impl).
#
# Caller must source src/common/print.sh first (uses printError / printInfo).
# Sets global BUILDS_ROOT; prints "Using external builds root: …" when EXTERNAL_BUILDS_ROOT is set and valid.
resolveBuildsRootFromRepoRoot() {
    local repoRoot="${1:?repository root required}"
    local resolvedExternalRoot="${EXTERNAL_BUILDS_ROOT:-}"
    while [[ "${resolvedExternalRoot}" == */ ]]; do
        resolvedExternalRoot="${resolvedExternalRoot%/}"
    done
    local usingExternalBuildsRoot=false
    if [ -n "${resolvedExternalRoot}" ]; then
        usingExternalBuildsRoot=true
        case "${resolvedExternalRoot}" in
            ~ )
                resolvedExternalRoot="${HOME}"
                ;;
            ~/* )
                resolvedExternalRoot="${resolvedExternalRoot/#\~/${HOME}}"
                ;;
        esac
        while [[ "${resolvedExternalRoot}" == */ ]]; do
            resolvedExternalRoot="${resolvedExternalRoot%/}"
        done
        case "${resolvedExternalRoot}" in
            '/'* )
                BUILDS_ROOT="${resolvedExternalRoot}"
                ;;
            * )
                printError "EXTERNAL_BUILDS_ROOT must be an absolute path or ~/… (relative paths are not supported)."
                return 1
                ;;
        esac
    else
        BUILDS_ROOT="${repoRoot%/}/builds"
    fi
    unset -v resolvedExternalRoot
    if [[ "${usingExternalBuildsRoot}" == true ]]; then
        if [ ! -d "${BUILDS_ROOT}" ]; then
            printError "EXTERNAL_BUILDS_ROOT is set but is not an existing directory: ${BUILDS_ROOT}"
            return 1
        fi
        printInfo "Using external builds root: ${BUILDS_ROOT}"
    fi
    unset -v usingExternalBuildsRoot
}
