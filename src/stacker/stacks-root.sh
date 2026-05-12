# shellcheck source=../common/print.sh
# Resolve STACKS_ROOT after user wsl-builds.conf has been sourced (EXTERNAL_STACKS_ROOT may be set).
# Shared by ./wsl-stacker.sh (via stacker-main.sh).
#
# Caller must source src/common/print.sh first (uses printError / printInfo).
# Sets global STACKS_ROOT; prints "Using external stacks root: …" when EXTERNAL_STACKS_ROOT is set and valid.
resolveStacksRootFromRepoRoot() {
    local repoRoot="${1:?repository root required}"
    local resolvedExternalRoot="${EXTERNAL_STACKS_ROOT:-}"
    while [[ "${resolvedExternalRoot}" == */ ]]; do
        resolvedExternalRoot="${resolvedExternalRoot%/}"
    done
    local usingExternalStacksRoot=false
    if [ -n "${resolvedExternalRoot}" ]; then
        usingExternalStacksRoot=true
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
                STACKS_ROOT="${resolvedExternalRoot}"
                ;;
            * )
                printError "EXTERNAL_STACKS_ROOT must be an absolute path or ~/… (relative paths are not supported)."
                return 1
                ;;
        esac
    else
        STACKS_ROOT="${repoRoot%/}/stacks"
    fi
    unset -v resolvedExternalRoot
    if [[ "${usingExternalStacksRoot}" == true ]]; then
        if [ ! -d "${STACKS_ROOT}" ]; then
            printError "EXTERNAL_STACKS_ROOT is set but is not an existing directory: ${STACKS_ROOT}"
            return 1
        fi
        printInfo "Using external stacks root: ${STACKS_ROOT}"
    fi
    unset -v usingExternalStacksRoot
}
