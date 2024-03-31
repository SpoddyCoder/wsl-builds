#!/usr/bin/env bash
PROJECT_DIR=~/resource-ai

if [ ! -z $INSTALL_SG3 ] && [ ! -f ${PROJECT_DIR}/stylegan3 ]; then

    printInfo "Cloning stylegan3 and stylegan3-fun repos"
    mkdir -p ${PROJECT_DIR}
    git clone https://github.com/NVlabs/stylegan3.git ${PROJECT_DIR}/stylegan3
    git clone https://github.com/PDillis/stylegan3-fun.git ${PROJECT_DIR}/stylegan3-fun
    # copy the maintained repo's environment.yml into the base stylegan3
    cp ${PROJECT_DIR}/stylegan3-fun/environment.yml ${PROJECT_DIR}/stylegan3/environment.yml

    # install & activate the environment using the file in the stylegan3 repo
    printInfo "Creating stylegan3 environment..."
    cd ${PROJECT_DIR}/stylegan3/
    conda env create -f environment.yml
    source ~/anaconda3/etc/profile.d/conda.sh
    conda activate stylegan3
    if [ ! -z $STYLEGAN3_PKL_CACHE ]; then
        printInfo "Setting up pkl cache dir on host path: $STYLEGAN3_PKL_CACHE"
        conda env config vars set DNNLIB_CACHE_DIR=${STYLEGAN3_PKL_CACHE} -n stylegan3
    fi
    if [ ! -z $STYLEGAN3_PYTORCH_CACHE ]; then
        printInfo "Setting up pytorch extensions cache dir on host path: $STYLEGAN3_PYTORCH_CACHE"
        conda env config vars set TORCH_EXTENSIONS_DIR=${STYLEGAN3_PYTORCH_CACHE} -n stylegan3
    fi

    printInfo "Note: both stylegan3 & stylegan3-fun repos use the same conda environment:"
    printInfo "    conda activate stylegan3"

    BUILD_UPDATED=true
    
fi


if [ ! -z $INSTALL_LSD ] && [ ! -f ${PROJECT_DIR}/lucid-sonic-dreams ]; then

    printInfo "Cloning nerdy rodent's lucid-sonic-dreams repo"
    git clone https://github.com/nerdyrodent/lucid-sonic-dreams.git ${PROJECT_DIR}/lucid-sonic-dreams

    printInfo "Creating an activating new lucid-sonic-dreams conda environment"
    cd ${PROJECT_DIR}/lucid-sonic-dreams
    conda create --name lucid-sonic-dreams python=3.9
    source ~/anaconda3/etc/profile.d/conda.sh
    conda activate lucid-sonic-dreams
    printInfo "Installing packages..."
    # NB: upgraded to cuda 12
    conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia
    # fix to versions as lsd is no longer maintained
    conda install numpy=1.19.5 scikit-image librosa=0.8.1 pygit2 pandas=1.4.4 gdown moviepy click ninja -c conda-forge
    pip install mega.py    # couldn't find this on conda
    pip install .    # make the lucidsonicdreams package available in this conda environment
    printInfo "Installing ubuntu ffmpeg with h264 codec"    # TODO: should be able to install this via conda
    conda remove --force ffmpeg
    sudo apt update
    sudo apt install libx264-dev ffmpeg

    printInfo "Note: to use the lucid-sonic-dreams project:"
    printInfo "    conda activate lucid-sonic-dreams"

    BUILD_UPDATED=true

fi


if [ ! -z $INSTALL_SPLEETER ] && [ ! -f ${PROJECT_DIR}/spleeter ]; then

    printInfo "Cloning spleeter repo"
    git clone https://github.com/deezer/spleeter.git ${PROJECT_DIR}/spleeter

    printInfo "Creating an activating new spleeter conda environment"
    cd ${PROJECT_DIR}/spleeter
    conda create --name spleeter python=3.9
    source ~/anaconda3/etc/profile.d/conda.sh
    conda activate spleeter
    printInfo "Installing poetry..."
    curl -sSL https://install.python-poetry.org | python3 -     # installs poetry here: /home/me/.local/share/pypoetry/venv/bin/poetry
    export PATH="$HOME/.local/share/pypoetry/venv/bin:$PATH"
    poetry config virtualenvs.create false
    printInfo "Using poetry to install spleeter deps..."
    poetry install
    printInfo "Installing spleeter..."
    pip install spleeter

    printInfo "Note: to use the spleeter project:"
    printInfo "    conda activate spleeter"

    BUILD_UPDATED=true

fi
