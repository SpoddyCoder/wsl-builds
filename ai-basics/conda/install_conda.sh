#!/usr/bin/env bash

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