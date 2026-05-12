#!/usr/bin/env bash

printInfo "Installing NFS client tools"
aptUpdateIfStale
sudo apt install -y \
    nfs-common

printInfo "NFS client tools installed"