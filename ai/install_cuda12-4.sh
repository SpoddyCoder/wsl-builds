#!/usr/bin/env bash

printInfo "Installing CUDA WSL 12.4"
cuda_version="12-4"
cuda_gpg_key_remove="7fa2af80"
cuda_wsl_pkg_repo_filename="cuda-wsl-ubuntu.pin"
cuda_wsl_pkg_repo_url="https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/${cuda_wsl_pkg_repo_filename}"
cuda_wsl_filename="cuda-repo-wsl-ubuntu-12-4-local_12.4.0-1_amd64.deb"
cuda_wsl_url="https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/${cuda_wsl_filename}"
# download the WSL version of CUDA
# - install the package repo
wget ${cuda_wsl_pkg_repo_url}   # small, no need to cache
sudo mv ${cuda_wsl_pkg_repo_filename} /etc/apt/preferences.d/cuda-repository-pin-600
# - install the pkg
sudo apt-key del ${cuda_gpg_key_remove}
getFile ${cuda_wsl_filename} ${cuda_wsl_url} "/tmp" cuda_installer
sudo dpkg -i "$cuda_installer"
sudo cp /var/cuda-repo-wsl-ubuntu-${cuda_version}-local/cuda-*-keyring.gpg /usr/share/keyrings/
# - install the cuda toolkit
sudo apt-get update
sudo apt-get -y install cuda-toolkit-${cuda_version}
cleanupGetFiles

# TODO: not required at this stage, but may be useful in the future
# Add the cuda install to the PATH inside .profile so nvcc works
# sudo tee -a ~/.profile > /dev/null <<EOF
# # include nvidia toolkit
# if [ -d "/usr/local/cuda/bin" ] ; then
#     PATH="/usr/local/cuda/bin:$PATH"
# Fi
# EOF