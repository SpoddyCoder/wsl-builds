#!/usr/bin/env bash

printInfo "Installing QoL npm globals"

# Install all development tools globally using npm
printInfo "Installing development tools globally via npm"
sudo npm install -g typescript eslint prettier pm2 nodemon serve

# Verify installations
printInfo "TypeScript version: $(tsc --version)"
printInfo "ESLint version: $(eslint --version)"
printInfo "Prettier version: $(prettier --version)"
printInfo "PM2 version: $(pm2 --version)"
printInfo "Nodemon version: $(nodemon --version)"
printInfo "Serve version: $(serve --version)"

printInfo "QoL npm globals installed"
