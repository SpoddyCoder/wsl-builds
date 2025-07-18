#!/usr/bin/env bash

printInfo "Installing k9s"

printInfo "Downloading k9s package..."
k9s_url="https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb"
getFile "k9s_linux_amd64.deb" "${k9s_url}" "/tmp" k9s_package

printInfo "Installing k9s package..."
sudo apt install -y "$k9s_package"

# Cleanup downloaded files
cleanupGetFiles

printInfo "k9s installed successfully..."
k9s version