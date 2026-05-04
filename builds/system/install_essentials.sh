#!/usr/bin/env bash

printInfo "Installing System essentials"
sudo apt update
sudo apt install -y \
    htop \
    rsync

printInfo "System essentials installed"