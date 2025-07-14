#!/usr/bin/env bash

printInfo "Installing AWS CLI"

printInfo "Installing dependencies..."
sudo apt-get install -y curl unzip

printInfo "Downloading and installing AWS CLI v2..."
getFile "awscli-exe-linux-x86_64.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" "/tmp" awscli_zip

# Save current directory before changing to /tmp
pwd=$(pwd)
cd /tmp
unzip "$awscli_zip"
sudo ./aws/install
rm -rf aws/
cleanupGetFiles
cd "$pwd"

printInfo "AWS CLI installed successfully..."
aws --version
printInfo "You should now set up your AWS config"
