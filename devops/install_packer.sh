#!/usr/bin/env bash

printInfo "Installing Packer"

printInfo "Adding HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

printInfo "Adding HashiCorp repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

printInfo "Installing Packer..."
sudo apt-get update && sudo apt-get install packer

printInfo "Installing Packer autocomplete..."
packer -autocomplete-install

printInfo "Packer installed successfully..."
packer --version
