#!/usr/bin/env bash

printInfo "Installing Docker"

printInfo "Installing dependencies"
sudo apt update
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
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

printInfo "Adding ${USER} to the docker group"
sudo groupadd -f docker
sudo usermod -aG docker "${USER}"

printInfo "Docker version: $(docker --version)"
printInfo "Docker Compose version: $(docker compose version | head -n1)"
printWarning "Restart your WSL session before running Docker without sudo."

if command -v systemctl >/dev/null 2>&1; then
    _docker_have_any_unit=0
    for _docker_u in docker.service docker.socket containerd.service; do
        if [ -f "/lib/systemd/system/${_docker_u}" ] || [ -f "/etc/systemd/system/${_docker_u}" ]; then
            _docker_have_any_unit=1
            break
        fi
    done
    if [ "${_docker_have_any_unit}" -eq 1 ]; then
        if promptYesNo "Disable Docker Engine, docker.socket, and containerd from starting on boot"; then
            # Stop/disable dependency-first: Engine (and socket) before containerd
            for _docker_u in docker.service docker.socket containerd.service; do
                if [ -f "/lib/systemd/system/${_docker_u}" ] || [ -f "/etc/systemd/system/${_docker_u}" ]; then
                    sudo systemctl disable --now "${_docker_u}"
                fi
            done
            printInfo "Docker-related systemd units are stopped and will not start automatically on boot"
        fi
    fi
fi

printInfo "Docker installed"
