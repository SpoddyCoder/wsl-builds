#!/usr/bin/env bash

printInfo "Installing StyleGAN3"

printInfo "Cloning stylegan3 and stylegan3-fun repos"
mkdir -p "${PROJECT_DIR}"
git clone https://github.com/NVlabs/stylegan3.git "${PROJECT_DIR}/stylegan3"
git clone https://github.com/PDillis/stylegan3-fun.git "${PROJECT_DIR}/stylegan3-fun"
# copy the maintained repo's environment.yml into the base stylegan3
cp "${PROJECT_DIR}/stylegan3-fun/environment.yml" "${PROJECT_DIR}/stylegan3/environment.yml"

# install & activate the environment using the file in the stylegan3 repo
printInfo "Creating stylegan3 environment"
cd "${PROJECT_DIR}/stylegan3/" || exit
conda env create -f environment.yml
# shellcheck source=/dev/null # conda.sh is provided by Anaconda at runtime
source ~/anaconda3/etc/profile.d/conda.sh
conda activate stylegan3
if [ -n "$STYLEGAN3_PKL_CACHE" ]; then
    printInfo "Setting up pkl cache dir on host path: $STYLEGAN3_PKL_CACHE"
    conda env config vars set DNNLIB_CACHE_DIR="${STYLEGAN3_PKL_CACHE}" -n stylegan3
fi
if [ -n "$STYLEGAN3_PYTORCH_CACHE" ]; then
    printInfo "Setting up pytorch extensions cache dir on host path: $STYLEGAN3_PYTORCH_CACHE"
    conda env config vars set TORCH_EXTENSIONS_DIR="${STYLEGAN3_PYTORCH_CACHE}" -n stylegan3
fi

printInfo "Note: both stylegan3 & stylegan3-fun repos use the same conda environment:"
printInfo "    conda activate stylegan3"

printInfo "StyleGAN3 installed"
