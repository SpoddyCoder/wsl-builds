#!/usr/bin/env bash

printInfo "Installing kubectl"

printInfo "Installing dependencies..."
sudo apt-get install -y curl

# Get the latest stable version
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

printInfo "Installing kubectl version ${KUBECTL_VERSION}..."
kubectl_url="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
kubectl_sha256_url="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"

# Download kubectl binary and checksum using getFile
getFile "kubectl" "${kubectl_url}" "/tmp" kubectl_binary
getFile "kubectl.sha256" "${kubectl_sha256_url}" "/tmp" kubectl_checksum

# Verify the download
echo "$(cat "$kubectl_checksum")  $(basename "$kubectl_binary")" | (cd "$(dirname "$kubectl_binary")" && sha256sum --check)

# Install kubectl
sudo install -o root -g root -m 0755 "$kubectl_binary" /usr/local/bin/kubectl

# Cleanup
cleanupGetFiles

printInfo "kubectl installed successfully..."
kubectl version --client 