#!/usr/bin/env bash


printInfo "Installing cursor development basics..."
sudo apt install -y \
    tree 

if ! grep -q "alias code='cursor'" ~/.bashrc; then
    printInfo "Adding cursor alias to ~/.bashrc"
    echo "" >> ~/.bashrc
    echo "# Cursor alias" >> ~/.bashrc
    echo "alias code='cursor'" >> ~/.bashrc
    source ~/.bashrc    # make the alias available immediately
else
    printInfo "Cursor alias already exists in ~/.bashrc"
fi

printInfo "Launching cursor, this should automatically install the extensions..."
cursor .
printInfo "cursor installation complete" 

printInfo "Cursor installation complete" 