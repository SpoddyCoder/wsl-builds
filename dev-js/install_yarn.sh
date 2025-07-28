#!/usr/bin/env bash

printInfo "Installing Yarn package manager via Corepack"

# Enable Corepack (comes with Node.js but is disabled by default)
printInfo "Enabling Corepack"
sudo corepack enable

# Install and activate the latest stable version of Yarn
printInfo "Installing and activating Yarn stable version"
corepack prepare yarn@stable --activate

printInfo "Yarn version: $(yarn --version)"

printInfo "Yarn installed successfully" 