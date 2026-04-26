#!/usr/bin/env bash

printInfo "Installing Docker"

printInfo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

printInfo "Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

printInfo "Adding Docker repository..."
ubuntu_codename=$(grep -oP '(?<=VERSION_CODENAME=).*' /etc/os-release || lsb_release -cs)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${ubuntu_codename} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

printInfo "Installing Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

printInfo "Adding ${USER} to the docker group..."
sudo groupadd -f docker
sudo usermod -aG docker "${USER}"

printInfo "Docker installed successfully..."
docker --version
docker compose version
printWarning "Restart your WSL session before running Docker without sudo."
