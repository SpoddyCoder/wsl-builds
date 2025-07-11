#!/usr/bin/env bash

printInfo "Installing Python3 development basics"
sudo apt install -y python3-pip

# Install basic Python packages
printInfo "Installing basic Python packages"
pip3 install --user \
    requests \
    numpy \
    pandas \
    matplotlib \
    jupyter \
    pytest \
    black \
    flake8 \
    mypy

printInfo "Python3 development basics installation complete" 