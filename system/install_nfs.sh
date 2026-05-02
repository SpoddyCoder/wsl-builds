#!/usr/bin/env bash

printInfo "Installing NFS client tools"
sudo apt update
sudo apt install -y \
    nfs-common

printInfo "NFS client tools installed"