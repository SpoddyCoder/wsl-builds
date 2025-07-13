#!/usr/bin/env bash

printInfo "Installing kubectl"

printInfo "Installing dependencies..."
sudo apt-get install -y curl

printInfo "Downloading kubectl..."
pwd=$(pwd)
cd /tmp

# Get the latest stable version
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

printInfo "Installing kubectl version ${KUBECTL_VERSION}..."
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"

# Verify the download
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Cleanup
rm -f kubectl kubectl.sha256
cd $pwd

printInfo "kubectl installed successfully..."
kubectl version --client 