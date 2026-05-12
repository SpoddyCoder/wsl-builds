#!/usr/bin/env bash
# Optional install-time opt-out from systemd start-on-boot. Requires prompt-yesno.sh.

# Returns 0 when systemctl exists and the systemd manager is running (running or degraded).
isSystemdManagerRunning() {
    command -v systemctl >/dev/null 2>&1 || return 1
    systemctl is-system-running --quiet
}

# Returns 0 when a unit file exists under /lib/systemd/system or /etc/systemd/system.
systemdUnitFilePresent() {
    local unit=$1
    [ -f "/lib/systemd/system/${unit}" ] || [ -f "/etc/systemd/system/${unit}" ]
}

# promptDisableSystemdUnitsOnBoot message unit [unit...]
# When the manager is running and at least one listed unit file exists, prompts to
# systemctl disable --now each present unit in argument order. Returns 0 when units
# were disabled; 1 when skipped or the user declines.
promptDisableSystemdUnitsOnBoot() {
    local msg=$1
    shift
    local unit
    local have_unit=1

    isSystemdManagerRunning || return 1

    for unit in "$@"; do
        if systemdUnitFilePresent "${unit}"; then
            have_unit=0
            break
        fi
    done
    [ "${have_unit}" -eq 0 ] || return 1

    if ! promptYesNo "${msg}"; then
        return 1
    fi

    for unit in "$@"; do
        if systemdUnitFilePresent "${unit}"; then
            sudo systemctl disable --now "${unit}"
        fi
    done
    return 0
}
