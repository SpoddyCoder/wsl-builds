#!/usr/bin/env bash
# Add-only, idempotent /etc/wsl.conf edits. Requires src/print.sh (sourced first).

readonly WSL_CONF_PATH=/etc/wsl.conf

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
