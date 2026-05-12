#!/usr/bin/env bash

printInfo "Installing System essentials"
aptUpdateIfStale
sudo apt install -y \
    htop \
    rsync

printInfo "System essentials installed"