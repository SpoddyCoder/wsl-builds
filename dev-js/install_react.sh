#!/usr/bin/env bash

printInfo "Installing React development tools"

# Install create-vite globally for modern React project scaffolding (replaces deprecated create-react-app)
printInfo "Installing create-vite globally for React project creation"
sudo npm install -g create-vite

# Install React Developer Tools CLI for debugging
printInfo "Installing React Developer Tools CLI"
sudo npm install -g react-devtools

# Verify installations
printInfo "Vite version: $(create-vite --version 2>/dev/null || echo 'installed via create-vite command')"
printInfo "React DevTools: $(which react-devtools)"

printInfo "React development tools installed successfully"
