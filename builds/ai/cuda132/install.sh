#!/usr/bin/env bash

printInfo "Installing CUDA WSL 13.2"

cuda_toolkit_apt="cuda-toolkit-13-2"
cuda_keyring_filename="cuda-keyring_1.1-1_all.deb"
cuda_keyring_url="https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/${cuda_keyring_filename}"
cuda_pin_filename="cuda-wsl-ubuntu.pin"
cuda_pin_url="https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/${cuda_pin_filename}"

wget "${cuda_pin_url}"
sudo mv "${cuda_pin_filename}" /etc/apt/preferences.d/cuda-repository-pin-600

getFile "${cuda_keyring_filename}" "${cuda_keyring_url}" "/tmp" cuda_keyring_deb
# shellcheck disable=SC2154 # cuda_keyring_deb is set by getFile via nameref
sudo dpkg -i "$cuda_keyring_deb"

aptUpdateRequired
sudo apt install -y "${cuda_toolkit_apt}"
cleanupGetFiles

cuda_nvcc="/usr/local/cuda/bin/nvcc"
if [[ -x "$cuda_nvcc" ]]; then
    printInfo "CUDA WSL version: $("$cuda_nvcc" --version 2>&1 | tail -n1)"
elif command -v nvcc >/dev/null 2>&1; then
    printInfo "CUDA WSL version: $(nvcc --version 2>&1 | tail -n1)"
fi

if [[ -d /usr/local/cuda/bin ]]; then
    replaceManagedShellRcRegion cuda-toolkit-path "$(printf "export PATH=\"/usr/local/cuda/bin:\${PATH}\"\n")"
fi

printInfo "CUDA WSL 13.2 installed"
