#!/usr/bin/env bash
# Add-only, idempotent /etc/wsl.conf edits. Requires src/common/print.sh (sourced first).

readonly WSL_CONF_PATH=/etc/wsl.conf

# wslConfSectionHasLine sectionName needle
# Returns 0 if needle appears as a substring on a line under [sectionName] (until the next [section]).
wslConfSectionHasLine() {
    local sectionName=$1
    local needle=$2

    if [[ ! -f "${WSL_CONF_PATH}" ]]; then
        return 1
    fi

    awk -v sec="${sectionName}" -v pat="${needle}" '
        /^\[/ {
            if ($0 == "[" sec "]") {
                in_section = 1
            } else {
                in_section = 0
            }
            next
        }
        in_section && index($0, pat) > 0 {
            found = 1
        }
        END {
            exit(found ? 0 : 1)
        }
    ' "${WSL_CONF_PATH}"
}

# ensureWslConfSectionLine sectionName needle lineToAdd
# Idempotent within [sectionName] only (unlike ensureWslConfIniLine, which greps the whole file).
ensureWslConfSectionLine() {
    local sectionName=$1
    local needle=$2
    local lineToAdd=$3

    if wslConfSectionHasLine "${sectionName}" "${needle}"; then
        return 0
    fi

    if ! grep -q "\\[${sectionName}\\]" "${WSL_CONF_PATH}" 2>/dev/null; then
        {
            printf '[%s]\n' "${sectionName}"
            printf '%s\n' "${lineToAdd}"
        } | sudo tee -a "${WSL_CONF_PATH}" > /dev/null
    else
        sudo sed -i "/\\[${sectionName}\\]/a ${lineToAdd}" "${WSL_CONF_PATH}"
    fi
    printInfo "Updated ${WSL_CONF_PATH} ([${sectionName}])"
}

# ensureWslConfIniLine sectionName needle lineToAdd
# needle: grep -qF match on $WSL_CONF_PATH; lineToAdd: single line appended under [sectionName].
ensureWslConfIniLine() {
    local sectionName=$1
    local needle=$2
    local lineToAdd=$3

    if grep -qF "${needle}" "${WSL_CONF_PATH}" 2>/dev/null; then
        return 0
    fi

    if ! grep -q "\\[${sectionName}\\]" "${WSL_CONF_PATH}" 2>/dev/null; then
        {
            printf '[%s]\n' "${sectionName}"
            printf '%s\n' "${lineToAdd}"
        } | sudo tee -a "${WSL_CONF_PATH}" > /dev/null
    else
        sudo sed -i "/\\[${sectionName}\\]/a ${lineToAdd}" "${WSL_CONF_PATH}"
    fi
    printInfo "Updated ${WSL_CONF_PATH} ([${sectionName}])"
}
