#!/usr/bin/env bash

printInfo "Installing SMB client tools"
aptUpdateIfStale
sudo apt install -y \
    smbclient \
    cifs-utils

printInfo "SMB client tools installed"