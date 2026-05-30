#!/usr/bin/env bash
# Resolve and normalize Windows host paths for wsl-builds.conf (configure wizard).
# Requires src/common/print.sh when callers use printError; configure.sh sources print.sh first.

resolveUserProfileUnix() {
    local winprofile launch_dir

    launch_dir=/mnt/c/Windows
    if [ ! -d "${launch_dir}" ]; then
        launch_dir=/mnt/c
    fi
    if [ ! -d "${launch_dir}" ]; then
        launch_dir=/
    fi

    # CMD can exit nonzero when started from a WSL UNC cwd even after printing %USERPROFILE%.
    winprofile=$( (cd "${launch_dir}" && cmd.exe /c "echo %USERPROFILE%") 2>/dev/null | tr -d '\r')
    if [ -z "${winprofile}" ]; then
        return 1
    fi
    winprofile="${winprofile##*$'\n'}"
    if [[ "${winprofile}" != [A-Za-z]:* ]]; then
        return 1
    fi
    wslpath -u "${winprofile}" 2>/dev/null || return 1
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
