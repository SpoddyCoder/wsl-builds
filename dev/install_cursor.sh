#!/usr/bin/env bash


printInfo "Installing Cursor"
sudo apt update
sudo apt install -y \
    tree 

if ! grep -q "alias code='cursor'" ~/.bashrc; then
    printInfo "Adding cursor alias to ~/.bashrc"
    {
        echo ""
        echo "# Cursor alias"
        echo "alias code='cursor'"
    } >> ~/.bashrc
else
    printInfo "Cursor alias already exists in ~/.bashrc"
fi

printInfo "Launching Cursor (first run may install extensions)"
cursor .

printInfo "Cursor installed"