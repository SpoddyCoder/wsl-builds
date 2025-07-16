#!/usr/bin/env bash

printInfo "Installing Terraform"

printInfo "Installing dependencies..."
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

printInfo "Adding HashiCorp GPG key..."
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

printInfo "Verifying GPG key..."
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

printInfo "Adding HashiCorp repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

printInfo "Installing Terraform..."
sudo apt-get update && sudo apt-get install -y terraform

printInfo "Installing Terraform autocomplete..."
terraform -install-autocomplete

printInfo "Terraform installed successfully..."
terraform --version 
