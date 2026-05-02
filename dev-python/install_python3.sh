#!/usr/bin/env bash

printInfo "Installing Python3 development basics"
sudo apt update
sudo apt install -y python3-pip

# TODO make this an additional arg
# Install basic Python packages
# printInfo "Installing basic Python packages"
# pip3 install --user \
#     requests \
#     numpy \
#     pandas \
#     matplotlib \
#     jupyter \
#     pytest \
#     black \
#     flake8 \
#     mypy

printInfo "Python3 version: $(python3 --version)"
printInfo "pip3 version: $(pip3 --version)"
printInfo "Python3 development basics installed"