#!/usr/bin/env bash
# Git credential warnings before sandbox harden. Requires REPO_ROOT (caller).

# shellcheck source=src/common/print.sh
source "${REPO_ROOT}/src/common/print.sh"
# shellcheck source=src/builder/wsl-builds-conf-migrate.sh
source "${REPO_ROOT}/src/builder/wsl-builds-conf-migrate.sh"

hostGitCredentialHelperLooksWindows() {
    local helper=$1

    [[ "${helper}" == *'/mnt/'* ]] && return 0
    [[ "${helper,,}" == *'.exe'* ]] && return 0
    return 1
}

warnHostGitCredentialsBeforeHarden() {
    local had_warning=false
    local git_helper host_conf_path line value warned_helper

    if git_helper=$(git config --global --get credential.helper 2>/dev/null); then
        if hostGitCredentialHelperLooksWindows "${git_helper}"; then
            printWarning "Git credential.helper points at a Windows host path (${git_helper}); it will not work after sandbox harden and restart"
            had_warning=true
            warned_helper="${git_helper}"
        fi
    fi

    if host_conf_path=$(resolveReadableHostWslBuildsConfPath); then
        while IFS= read -r line || [[ -n "${line}" ]]; do
            if [[ "${line}" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            if [[ ! "${line}" =~ ^[[:space:]]*GIT_CREDENTIALS_HELPER[[:space:]]*= ]]; then
                continue
            fi
            value="${line#*=}"
            value="${value%%#*}"
            if hostGitCredentialHelperLooksWindows "${value}"; then
                if [[ "${had_warning}" == true && "${value}" == "${warned_helper}" ]]; then
                    continue
                fi
                printWarning "GIT_CREDENTIALS_HELPER in ${host_conf_path} points at a Windows host path; it will not work after sandbox harden and restart"
                had_warning=true
            fi
        done <"${host_conf_path}"
    fi

    if [[ "${had_warning}" == true ]]; then
        printInfo "After restart, re-authenticate with SSH keys, gh auth login, or a Linux git credential helper"
        printInfo "Remove the Windows helper with: git config --global --unset credential.helper — then configure Linux auth"
    fi
}
