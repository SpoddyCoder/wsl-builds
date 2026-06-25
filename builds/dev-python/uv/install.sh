#!/usr/bin/env bash

printInfo "Installing uv"

uv_install_url="https://astral.sh/uv/install.sh"
getFile "uv_install.sh" "${uv_install_url}" "" uv_install_script

printInfo "Running uv official install script"
# shellcheck disable=SC2154 # uv_install_script is set by getFile via nameref
sh "$uv_install_script"

cleanupGetFiles

_uv_bin="${HOME}/.local/bin/uv"
if [[ -x "${_uv_bin}" ]]; then
    printInfo "uv version: $("${_uv_bin}" --version)"
else
    printInfo "uv version: $(uv --version 2>&1 | head -n1)"
fi

printInfo "uv installed"
