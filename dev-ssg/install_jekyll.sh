#!/usr/bin/env bash

printInfo "Installing Jekyll static site generator"

# Install Ruby and development dependencies
printInfo "Installing Ruby and build dependencies"
sudo apt update
sudo apt install -y ruby-full build-essential zlib1g-dev

# Set up gem installation directory for user (avoid root gems)
printInfo "Configuring gem installation directory"
if ! grep -q "GEM_HOME.*gems" ~/.bashrc; then
    echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
    echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
    echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
fi

# Apply environment variables for current session
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

# Install Jekyll and Bundler
printInfo "Installing Jekyll and Bundler via gem"
gem install jekyll bundler

# Verify installation
printInfo "Jekyll version: $(jekyll --version)"
printInfo "Bundler version: $(bundler --version)"

printInfo "Jekyll installed successfully"
printInfo "Note: You may need to restart your shell or run 'source ~/.bashrc' to use Jekyll commands" 