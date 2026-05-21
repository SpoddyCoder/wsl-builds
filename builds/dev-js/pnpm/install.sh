#!/usr/bin/env bash

printInfo "Installing pnpm"

# Enable Corepack (comes with Node.js but is disabled by default)
printInfo "Enabling Corepack"
sudo corepack enable

# Install and activate the latest stable version of pnpm
printInfo "Installing and activating pnpm latest version"
corepack prepare pnpm@latest --activate

printInfo "pnpm version: $(pnpm --version)"

printInfo "pnpm installed"
