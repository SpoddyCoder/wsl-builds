#!/usr/bin/env bash

printInfo "Cloning re-dalle repo"
git clone https://github.com/ai-forever/ru-dalle.git ${PROJECT_DIR}/ru-dalle

printInfo "Creating an activating new ru-dalle conda environment"
cd ${PROJECT_DIR}/ru-dalle
conda create --name ru-dalle python=3.9
source ~/anaconda3/etc/profile.d/conda.sh
conda activate ru-dalle

printInfo "Installing Cython..."
pip install Cython
printInfo "Installing ru-dalle dependencies..."
pip install -r requirements.txt
pip install ruclip  # additional dep for minimal example
pip install --upgrade huggingface_hub   # 
# pip install requests==2.27.1
# pip install urllib3==1.25.11
pip install .    # make the rudalle package available in this conda environment

printInfo "Note: to use the ru-dalle project:"
printInfo "    conda activate ru-dalle"
