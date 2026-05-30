#!/usr/bin/env bash
# Host → ~/.wsl-builds.conf migration and /mnt/ path review. Requires REPO_ROOT (caller).

# shellcheck source=src/common/print.sh
source "${REPO_ROOT}/src/common/print.sh"
# shellcheck source=src/common/prompt-yesno.sh
source "${REPO_ROOT}/src/common/prompt-yesno.sh"
# shellcheck source=src/builder/shell-rc.sh
source "${REPO_ROOT}/src/builder/shell-rc.sh"
# shellcheck source=src/builder/host-wsl-builds-conf-paths.sh
source "${REPO_ROOT}/src/builder/host-wsl-builds-conf-paths.sh"

resolveReadableHostWslBuildsConfPath() {
    local default_path

    if [ -n "${WSL_BUILDS_CONF:-}" ] && [ -r "${WSL_BUILDS_CONF}" ]; then
        printf '%s\n' "${WSL_BUILDS_CONF}"
        return 0
    fi
    if default_path=$(defaultHostConfPath) && [ -r "${default_path}" ]; then
        printf '%s\n' "${default_path}"
        return 0
    fi
    return 1
}

migrateHostWslBuildsConfToHome() {
    local host_path dest
    dest="${HOME}/.wsl-builds.conf"

    if ! host_path=$(resolveReadableHostWslBuildsConfPath); then
        printInfo "No host wsl-builds.conf found; skipping migration to ${dest}"
        return 0
    fi

    if ! promptYesNoDefaultYesOnEof "Copy host wsl-builds.conf to ${dest} and switch to local config (removes WSL_BUILDS_CONF from shell rc)?"; then
        return 0
    fi

    if [ -f "${dest}" ]; then
        if ! promptYesNoDefaultNo "${dest} already exists; overwrite with host config?"; then
            return 0
        fi
    fi

    cp "${host_path}" "${dest}"
    removeManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}"
    printInfo "Migrated wsl-builds.conf to local config: ${dest}"
    printInfo "Edit with: nano ${dest}"
}

printWslBuildsConfMntPathReviewReminder() {
    local conf_path line display
    local -a mnt_lines=()
    conf_path="${HOME}/.wsl-builds.conf"

    [[ -f "${conf_path}" ]] || return 0

    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ "${line}" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        if [[ "${line}" == *'/mnt/'* ]]; then
            mnt_lines+=("${line}")
        fi
    done <"${conf_path}"

    if ((${#mnt_lines[@]} > 0)); then
        printWarning "Found ${#mnt_lines[@]} non-comment line(s) in ${conf_path} pointing at Windows host mounts (/mnt/...)"
        printInfo "Review ${conf_path} and remove or change settings pointing at Windows host mounts (/mnt/...)"
        for line in "${mnt_lines[@]}"; do
            if ((${#line} > 120)); then
                display="${line:0:120}..."
            else
                display="${line}"
            fi
            printInfo "  ${display}"
        done
        return 0
    fi

    printInfo "No /mnt/ paths in local wsl-builds.conf"
}
