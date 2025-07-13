#!/usr/bin/env bash

printInfo "Installing AWS CLI"

printInfo "Installing dependencies..."
sudo apt-get install -y curl unzip

printInfo "Downloading and installing AWS CLI v2..."
pwd=$(pwd)      # download into tmp so anything not cleaned up is removed at reboot, TODO: should be done by the helper
cd /tmp
getFile "awscli-exe-linux-x86_64.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip awscli-exe-linux-x86_64.zip
sudo ./aws/install
rm -rf awscli-exe-linux-x86_64.zip aws/
cd $pwd

printInfo "AWS CLI installed successfully..."
aws --version
printInfo "You should now set up your AWS credentials, eg:"
printInfo "    aws configure"
printInfo "    aws configure sso"
