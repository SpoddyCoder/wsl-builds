#!/usr/bin/env bash

printInfo "Installing Hugo static site generator"

# Install Hugo extended edition via apt package manager
printInfo "Installing Hugo extended edition from Ubuntu repository"
sudo apt update
sudo apt install -y hugo

# Verify installation
printInfo "Hugo version: $(hugo version)"

printInfo "Hugo installed successfully" 