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

# promptRemoveHostHomeSymlinks
# Offers to remove symlinks directly under $HOME whose target is under /mnt/ (host paths).
promptRemoveHostHomeSymlinks() {
    local link target resolved had_host_symlink=false

    while IFS= read -r -d '' link; do
        target=$(readlink "${link}")
        resolved="${target}"
        if [[ -e "${link}" ]]; then
            resolved=$(readlink -f "${link}" 2>/dev/null || echo "${target}")
        fi
        if [[ "${resolved}" != /mnt/* ]]; then
            continue
        fi
        had_host_symlink=true
        printInfo "Host symlink ${link} -> ${target}"
        if promptYesNoDefaultNo "Remove symlink ${link} -> ${target}?"; then
            rm "${link}"
            printInfo "Removed host symlink ${link}"
        fi
    done < <(find "${HOME}" -maxdepth 1 -type l -print0 2>/dev/null)

    if [[ "${had_host_symlink}" == false ]]; then
        printInfo "No host symlinks under ${HOME} pointing at /mnt"
    fi
}
