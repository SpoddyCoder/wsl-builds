#!/usr/bin/env bash

if [ ! -z $INSTALL_CONDA ] && ! (conda --version) > /dev/null 2>&1; then

    printInfo "Installing Anaconda"
    conda_filename="Anaconda3-2024.02-1-Linux-x86_64.sh"
    conda_url="https://repo.anaconda.com/archive/${conda_filename}"
    # install Anaconda: https://www.anaconda.com/download#downloads
    getFile ${conda_filename} ${conda_url}
    bash $conda_filename
    rm $conda_filename

    printInfo "Disabling auto_activate_base"
    echo "auto_activate_base: false" > ~/.condarc

    # this is a nice idea! But the Windows host having case insenstive filesystem while the Linux OS has case-senstive proves to be a big problem :(
    # https://github.com/conda/conda/issues/6514
    # https://github.com/conda/conda/issues/10333
    # possible future workaround is to create a case sensitive filesystem on the host - lot of faff tho
    # if [ ! -z $CONDA_PKG_CACHE ]; then
    #     # https://docs.anaconda.com/free/working-with-conda/packages/shared-pkg-cache/
    #     if ! cat ~/.condarc | grep -q "$CONDA_PKG_CACHE"; then
    #         printInfo "Setting up shared conda package cache to use host path: $CONDA_PKG_CACHE"
    #         echo "pkgs_dirs:" >> ~/.condarc
    #         echo "    - $CONDA_PKG_CACHE" >> ~/.condarc
    #     fi
    # fi

    BUILD_UPDATED=true

fi


if [ ! -z $INSTALL_CUDA124 ] && [ ! -f /etc/apt/preferences.d/cuda-repository-pin-600 ]; then

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
    getFile ${cuda_wsl_filename} ${cuda_wsl_url}
    sudo dpkg -i ${cuda_wsl_filename}
    sudo cp /var/cuda-repo-wsl-ubuntu-${cuda_version}-local/cuda-*-keyring.gpg /usr/share/keyrings/
    # - install the cuda toolkit
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-${cuda_version}
    rm $cuda_wsl_filename

    # TODO: not required at this stage, but may be useful in the future
    # Add the cuda install to the PATH inside .profile so nvcc works
    # sudo tee -a ~/.profile > /dev/null <<EOF
    # # include nvidia toolkit
    # if [ -d "/usr/local/cuda/bin" ] ; then
    #     PATH="/usr/local/cuda/bin:$PATH"
    # Fi
    # EOF

    BUILD_UPDATED=true

fi
