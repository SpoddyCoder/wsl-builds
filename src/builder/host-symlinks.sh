#!/usr/bin/env bash
# Host symlinks from wsl-builds.conf SYMLINK_HOST_* keys. Requires src/common/print.sh (sourced first).

# installHostSymlinksFromConf
# After wsl-builds.conf is sourced, creates ${HOME}/<basename> -> target for each
# SYMLINK_HOST_* variable (basename: strip prefix, lowercase, underscores to hyphens).
installHostSymlinksFromConf() {
    local -a vars=()
    local var target basename link had_nonempty=false

    mapfile -t vars < <(compgen -v 'SYMLINK_HOST_' | sort)

    if ((${#vars[@]} == 0)); then
        printInfo "No SYMLINK_HOST_* entries configured, skipping host symlinks"
        return 0
    fi

    for var in "${vars[@]}"; do
        target="${!var-}"
        if [[ -z "${target}" ]]; then
            continue
        fi
        had_nonempty=true
        while [[ "${target}" == */ ]]; do
            target="${target%/}"
        done

        basename="${var#SYMLINK_HOST_}"
        basename="${basename,,}"
        basename="${basename//_/-}"
        link="${HOME}/${basename}"

        if [[ -L "${link}" ]]; then
            printInfo "Skipping host symlink ${link} (already exists)"
            continue
        fi

        printInfo "Creating host symlink ${link} -> ${target}"
        ln -s "${target}" "${link}"
    done

    if [[ "${had_nonempty}" == false ]]; then
        printInfo "No SYMLINK_HOST_* entries configured, skipping host symlinks"
    fi
}
