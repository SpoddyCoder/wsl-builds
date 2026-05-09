# Configure wizard implementation: sourced by ./configure.sh after bootstrap and print.sh.

# shellcheck source=src/common/prompt-yesno.sh
source "${REPO_ROOT}/src/common/prompt-yesno.sh"
# shellcheck source=src/builder/shell-rc.sh
source "${REPO_ROOT}/src/builder/shell-rc.sh"

NONINTERACTIVE=false

showWizardUsage() {
    cat <<'EOF'
Usage: ./configure.sh [options]

Configure a shared wsl-builds.conf on the Windows host (WSL_BUILDS_CONF in ~/.bashrc and/or ~/.zshrc),
or create ~/.wsl-builds.conf from the example in this repo.

Options:
  --noninteractive  If default Windows host wsl-builds.conf exists, adopt it; else copy example to ~/.wsl-builds.conf if missing; no prompts
  -h, --help                    Show this help
EOF
}

parseWizardArgs() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --noninteractive)
                NONINTERACTIVE=true
                shift
                ;;
            -h | --help)
                showWizardUsage
                exit 0
                ;;
            *)
                printError "Unknown option: $1"
                showWizardUsage >&2
                exit 1
                ;;
        esac
    done
}

autoNonInteractiveIfNoTTY() {
    if [ ! -t 0 ]; then
        NONINTERACTIVE=true
    fi
}

resolveUserProfileUnix() {
    local winprofile
    if ! winprofile=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r'); then
        return 1
    fi
    if [ -z "${winprofile}" ]; then
        return 1
    fi
    wslpath -u "$winprofile" 2>/dev/null || return 1
}

defaultHostConfPath() {
    local profileUnix
    if ! profileUnix=$(resolveUserProfileUnix); then
        return 1
    fi
    printf '%s\n' "${profileUnix}/.wsl-builds/wsl-builds.conf"
}

normalizeHostConfPath() {
    local raw=$1
    local out
    if [ -z "${raw}" ]; then
        return 1
    fi
    # Readable Unix path as given
    if [[ "${raw}" == /* ]] && [ -r "${raw}" ]; then
        printf '%s\n' "${raw}"
        return 0
    fi
    # Windows-style or mixed — wslpath -u accepts "C:\..." or "C:/..."
    if out=$(wslpath -u "${raw}" 2>/dev/null) && [ -n "${out}" ]; then
        printf '%s\n' "${out}"
        return 0
    fi
    return 1
}

printReloadHint() {
    printInfo "Load this shell setting in new terminals, or run: source ~/.bashrc"
    if [[ -f "${HOME}/.zshrc" ]] && grep -qF '# >>> wsl-builds:wsl-builds-conf >>>' "${HOME}/.zshrc" 2>/dev/null; then
        printInfo "If you use zsh: source ~/.zshrc"
    fi
}

printHomeConfShellHint() {
    if [ -n "${WSL_BUILDS_CONF:-}" ]; then
        printWarning "WSL_BUILDS_CONF still set — the builder uses it instead of ~/.wsl-builds.conf; unset WSL_BUILDS_CONF or start a new terminal"
    fi
}

adoptHostConfPath() {
    local path=$1
    local body
    export WSL_BUILDS_CONF="${path}"
    body="$(printf 'export WSL_BUILDS_CONF=%q\n' "${path}")"
    replaceManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}" "${body}"
    printInfo "Using host config: ${path}"
    printInfo "WSL_BUILDS_CONF saved (wsl-builds:${SHELL_RC_WIZARD_REGION_ID})"
    printReloadHint
}

copyExampleIfMissing() {
    local example="${REPO_ROOT}/wsl-builds.conf.example"
    local dest="${HOME}/.wsl-builds.conf"
    # Home config is used when WSL_BUILDS_CONF is unset; drop a stale managed export.
    removeManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}"
    if [ -f "${dest}" ]; then
        printInfo "Config already exists: ${dest}"
        printInfo "Edit with: nano ${dest}"
        printHomeConfShellHint
        return 0
    fi
    cp "${example}" "${dest}"
    printInfo "Created ${dest} from example"
    printInfo "Edit with: nano ${dest}"
    printHomeConfShellHint
}

runNonInteractive() {
    local default_path
    default_path=""
    if default_path=$(defaultHostConfPath); then
        :
    else
        default_path=""
    fi
    if [ -n "${default_path}" ] && [ -r "${default_path}" ]; then
        adoptHostConfPath "${default_path}"
        return 0
    fi
    copyExampleIfMissing
}

stepDefaultHostConfInteractive() {
    local default_path parent example
    example="${REPO_ROOT}/wsl-builds.conf.example"
    if ! default_path=$(defaultHostConfPath); then
        printInfo "Could not resolve the default Windows host path for wsl-builds.conf (normally %USERPROFILE%\\.wsl-builds\\wsl-builds.conf when run from WSL)."
        return 1
    fi
    printInfo "Checking for wsl-builds.conf on Windows host at ${default_path}"
    [ -n "${default_path}" ] || return 1
    if [ -f "${default_path}" ] && [ -r "${default_path}" ]; then
        if promptYesNo "Found default host config at ${default_path}. Use it?"; then
            adoptHostConfPath "${default_path}"
            exit 0
        fi
        return 1
    fi
    if [ -e "${default_path}" ]; then
        if [ -f "${default_path}" ] && [ ! -r "${default_path}" ]; then
            printWarning "A file exists at ${default_path} but is not readable — fix permissions or remove it, then re-run."
        else
            printWarning "${default_path} exists but is not a regular readable file — remove it or pick another path, then re-run."
        fi
        return 1
    fi
    if promptYesNo "Not found - do you want to create one?"; then
        parent=$(dirname "${default_path}")
        if ! mkdir -p "${parent}"; then
            printError "Could not create directory: ${parent}"
            return 1
        fi
        if ! cp "${example}" "${default_path}"; then
            printError "Could not create ${default_path}"
            return 1
        fi
        printInfo "Created ${default_path} from example"
        printInfo "Edit with: nano ${default_path}"
        adoptHostConfPath "${default_path}"
        exit 0
    fi
    return 1
}

stepCustomHostPathInteractive() {
    if ! promptYesNo "Do you have a wsl-builds.conf at another path on the Windows host?"; then
        return 1
    fi
    local raw normalized
    while true; do
        printf '%s' "Enter path (Windows or WSL, e.g. C:\\Users\\me\\custom\\wsl-builds.conf): "
        read -r raw || exit 1
        if [ -z "${raw}" ]; then
            printWarning "Empty path; try again or press Ctrl+C to abort."
            continue
        fi
        if ! normalized=$(normalizeHostConfPath "${raw}"); then
            printWarning "Could not convert path; check spelling."
            continue
        fi
        if [ ! -r "${normalized}" ]; then
            printWarning "Not a readable file: ${normalized}"
            continue
        fi
        adoptHostConfPath "${normalized}"
        exit 0
    done
}

mainWizard() {
    parseWizardArgs "$@"
    autoNonInteractiveIfNoTTY

    if [ "${NONINTERACTIVE}" = true ]; then
        runNonInteractive
        exit 0
    fi

    stepDefaultHostConfInteractive || true
    stepCustomHostPathInteractive || true

    copyExampleIfMissing
}
