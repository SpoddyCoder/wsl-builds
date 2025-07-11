#!/usr/bin/env bash

printInfo "Installing dev essentials"
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    jq \
    yq \
    htop \
    rsync

printInfo "Essential dev packages installation complete" 