#!/usr/bin/env bash

printInfo "Installing Terraform"

printInfo "Installing dependencies..."
sudo apt-get install -y curl unzip gnupg software-properties-common

printInfo "Adding HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

printInfo "Adding HashiCorp repository..."
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

printInfo "Installing Terraform..."
sudo apt-get update && sudo apt-get install -y terraform

printInfo "Terraform installed successfully..."
terraform --version 
