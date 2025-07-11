#!/usr/bin/env bash

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