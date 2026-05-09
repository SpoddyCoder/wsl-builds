#!/usr/bin/env bash

printInfo "Installing Node.js"

# Download and run the NodeSource setup script for LTS version
printInfo "Adding NodeSource repository for Node.js LTS"
getFile "nodesource_setup.sh" "https://deb.nodesource.com/setup_lts.x" "" nodesource_script

# Run the setup script to add the repository
# shellcheck disable=SC2154 # nodesource_script is set by getFile via nameref
sudo bash "$nodesource_script"

# Update package cache and install Node.js
printInfo "Installing Node.js and npm"
sudo apt update
sudo apt install -y nodejs

cleanupGetFiles

printInfo "Node.js version: $(node -v)"
printInfo "npm version: $(npm -v)"

printInfo "Node.js installed"