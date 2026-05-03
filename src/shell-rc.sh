#!/usr/bin/env bash
# Named regions in ~/.bashrc and ~/.zshrc. Requires src/print.sh (sourced first).

readonly SHELL_RC_LEGACY_MANAGED_BEGIN='# >>> wsl-builds (managed) >>>'
readonly SHELL_RC_LEGACY_MANAGED_END='# <<< wsl-builds (managed) <<<'
readonly SHELL_RC_WIZARD_REGION_ID='wsl-builds-conf'

shellRcValidateRegionId() {
    if [[ ! "${1:-}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        printError "Invalid shell rc region id: ${1:-}"
        return 1
    fi
}

# Prints one path per line: existing ~/.bashrc and/or ~/.zshrc; if neither exists, ~/.bashrc.
shellRcTargetPaths() {
    local any=false
    if [[ -f "${HOME}/.bashrc" ]]; then
        printf '%s\n' "${HOME}/.bashrc"
        any=true
    fi
    if [[ -f "${HOME}/.zshrc" ]]; then
        printf '%s\n' "${HOME}/.zshrc"
        any=true
    fi
    if [[ "${any}" == false ]]; then
        printf '%s\n' "${HOME}/.bashrc"
    fi
}

# Strip named region; if regionId is wsl-builds-conf, also strip legacy (managed) block.
shellRcStripRegionFromFile() {
    local file=$1
    local regionId=$2
    local begin end stripLegacy=false

    begin="# >>> wsl-builds:${regionId} >>>"
    end="# <<< wsl-builds:${regionId} <<<"
    if [[ "${regionId}" == "${SHELL_RC_WIZARD_REGION_ID}" ]]; then
        stripLegacy=true
    fi

    [[ -f "${file}" ]] || return 0

    local tmp inNamed inLegacy
    tmp="$(mktemp)"
    inNamed=false
    inLegacy=false
    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ "${inNamed}" == true ]]; then
            if [[ "${line}" == "${end}" ]]; then
                inNamed=false
            fi
            continue
        fi
        if [[ "${stripLegacy}" == true && "${inLegacy}" == true ]]; then
            if [[ "${line}" == "${SHELL_RC_LEGACY_MANAGED_END}" ]]; then
                inLegacy=false
            fi
            continue
        fi
        if [[ "${line}" == "${begin}" ]]; then
            inNamed=true
            continue
        fi
        if [[ "${stripLegacy}" == true && "${line}" == "${SHELL_RC_LEGACY_MANAGED_BEGIN}" ]]; then
            inLegacy=true
            continue
        fi
        printf '%s\n' "${line}"
    done <"${file}" >"${tmp}"
    mv "${tmp}" "${file}"
}

removeManagedShellRcRegion() {
    local regionId=$1
    shellRcValidateRegionId "${regionId}" || return 1

    local p sumBefore sumAfter
    for p in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
        [[ -f "${p}" ]] || continue
        sumBefore="$(sha256sum "${p}" | awk '{ print $1 }')"
        shellRcStripRegionFromFile "${p}" "${regionId}"
        sumAfter="$(sha256sum "${p}" | awk '{ print $1 }')"
        if [[ "${sumBefore}" != "${sumAfter}" ]]; then
            printInfo "Updated ${p} (removed wsl-builds:${regionId})"
        fi
    done
}

replaceManagedShellRcRegion() {
    local regionId=$1
    local body=$2
    shellRcValidateRegionId "${regionId}" || return 1

    local begin end p paths
    begin="# >>> wsl-builds:${regionId} >>>"
    end="# <<< wsl-builds:${regionId} <<<"

    mapfile -t paths < <(shellRcTargetPaths)
    for p in "${paths[@]}"; do
        shellRcStripRegionFromFile "${p}" "${regionId}"
        {
            printf '%s\n' "${begin}"
            printf '%s\n' "${body}"
            printf '%s\n' "${end}"
        } >>"${p}"
        printInfo "Updated ${p} (wsl-builds:${regionId})"
    done
}

ensureShellRcRegion() {
    local regionId=$1
    local body=$2
    shellRcValidateRegionId "${regionId}" || return 1

    local begin end p
    begin="# >>> wsl-builds:${regionId} >>>"
    end="# <<< wsl-builds:${regionId} <<<"

    local paths
    mapfile -t paths < <(shellRcTargetPaths)
    for p in "${paths[@]}"; do
        if [[ -f "${p}" ]] && grep -qF "${begin}" "${p}"; then
            continue
        fi
        {
            printf '%s\n' "${begin}"
            printf '%s\n' "${body}"
            printf '%s\n' "${end}"
        } >>"${p}"
        printInfo "Updated ${p} (wsl-builds:${regionId})"
    done
}
