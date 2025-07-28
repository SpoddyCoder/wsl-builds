#!/usr/bin/env bash

printInfo "Installing NVM (Node Version Manager) latest version"

# Download the NVM installation script from the official GitHub repository
printInfo "Downloading NVM installation script from GitHub"
getFile "nvm_install.sh" "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh" "" nvm_script

# Run the installation script
printInfo "Running NVM installation script"
bash "$nvm_script"

cleanupGetFiles

# Activate NVM in current session
printInfo "Activating NVM for current session"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

printInfo "NVM version: $(nvm --version)"

printInfo "NVM installed successfully" 