#!/usr/bin/env bash

printInfo "Installing Docker"

printInfo "Installing dependencies"
aptUpdateIfStale
sudo apt install -y ca-certificates curl gnupg

printInfo "Adding Docker GPG key"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

printInfo "Adding Docker repository"
ubuntu_codename=$(grep -oP '(?<=VERSION_CODENAME=).*' /etc/os-release || lsb_release -cs)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${ubuntu_codename} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

printInfo "Installing Docker Engine"
aptUpdateRequired
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

printInfo "Adding ${USER} to the docker group"
sudo groupadd -f docker
sudo usermod -aG docker "${USER}"

printInfo "Docker version: $(docker --version)"
printInfo "Docker Compose version: $(docker compose version | head -n1)"
printWarning "Restart your WSL session before running Docker without sudo."

if promptDisableSystemdUnitsOnBoot "Disable Docker Engine, docker.socket, and containerd from starting on boot" \
    docker.service docker.socket containerd.service; then
    printInfo "Docker-related systemd units are stopped and will not start automatically on boot"
fi

printInfo "Docker installed"
