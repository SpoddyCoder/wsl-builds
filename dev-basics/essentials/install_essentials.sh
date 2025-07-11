#!/usr/bin/env bash

printInfo "Installing development essentials"
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    unzip \
    zip \
    jq \
    yq \
    rsync

printInfo "Essential development packages installation complete" 