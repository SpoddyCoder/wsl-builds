#!/usr/bin/env bash

printInfo "Installing Next.js development tools"

# Install create-next-app globally for Next.js project scaffolding
printInfo "Installing create-next-app globally for Next.js project creation"
sudo npm install -g create-next-app

# Verify installation
printInfo "create-next-app version: $(create-next-app --version)"

printInfo "Next.js development tools installed successfully"
