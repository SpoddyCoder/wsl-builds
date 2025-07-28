#!/usr/bin/env bash

printInfo "Installing Vue.js development tools"

# Install create-vue globally for modern Vue project scaffolding (Vite-powered, replaces Vue CLI)
printInfo "Installing create-vue globally for Vue project creation"
sudo npm install -g create-vue@latest

printInfo "Vue.js development tools installed successfully" 