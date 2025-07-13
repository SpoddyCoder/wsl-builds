#!/usr/bin/env bash

printInfo "Installing system essentials"
sudo apt install -y \
    htop \
    rsync

printInfo "System essentials installation complete" 