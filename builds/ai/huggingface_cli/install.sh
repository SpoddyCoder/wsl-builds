#!/usr/bin/env bash

printInfo "Installing Hugging Face Hub CLI"

printInfo "Installing dependencies"
aptUpdateIfStale
sudo apt install -y python3 python3-pip

printInfo "Installing huggingface_hub with CLI extra via pip"
# Ubuntu 24.04+ system Python is PEP 668 managed; user-site install needs this flag.
python3 -m pip install --user --break-system-packages 'huggingface_hub[cli]'

_hf_bin="${HOME}/.local/bin/hf"
if [[ -n "${HF_HOME:-}" ]] || [[ -n "${HF_HUB_CACHE:-}" ]]; then
    printInfo "Configuring Hugging Face environment from wsl-builds.conf"
    _hf_owner="${SUDO_USER:-$USER}"
    _hf_group="$(id -gn "${_hf_owner}")"

    if [[ -n "${HF_HOME:-}" ]]; then
        printInfo "Preparing HF_HOME directory: ${HF_HOME}"
        sudo install -d -m 0755 "${HF_HOME}"
        sudo chown "${_hf_owner}:${_hf_group}" "${HF_HOME}"
    fi
    if [[ -n "${HF_HUB_CACHE:-}" ]]; then
        printInfo "Preparing HF_HUB_CACHE directory: ${HF_HUB_CACHE}"
        sudo install -d -m 0755 "${HF_HUB_CACHE}"
        sudo chown "${_hf_owner}:${_hf_group}" "${HF_HUB_CACHE}"
    fi

    _hf_profile="/etc/profile.d/wsl-builds-huggingface-env.sh"
    {
        [[ -n "${HF_HOME:-}" ]] && printf 'export HF_HOME=%q\n' "${HF_HOME}"
        [[ -n "${HF_HUB_CACHE:-}" ]] && printf 'export HF_HUB_CACHE=%q\n' "${HF_HUB_CACHE}"
    } | sudo tee "${_hf_profile}" >/dev/null
    sudo chmod 0644 "${_hf_profile}"
fi

if [[ -x "${_hf_bin}" ]]; then
    printInfo "Hugging Face Hub CLI version: $("${_hf_bin}" version 2>&1 | head -n1)"
else
    printInfo "Hugging Face Hub CLI version: $(python3 -c "from huggingface_hub import __version__; print(__version__)" 2>&1)"
fi

printInfo "Hugging Face Hub CLI installed"
