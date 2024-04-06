#!/usr/bin/env bash

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
