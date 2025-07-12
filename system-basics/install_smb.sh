#!/usr/bin/env bash

printInfo "Installing SMB client tools"
sudo apt install -y \
    smbclient \
    cifs-utils

printInfo "SMB client tools installation complete" 