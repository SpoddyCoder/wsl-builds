#!/usr/bin/env bash

printInfo "Installing systemd tools"
sudo apt install -y \
    systemd \
    systemd-sysv

# Configure WSL to use systemd
if ! sudo cat /etc/wsl.conf | grep -q "systemd=true" > /dev/null 2>&1; then
    if ! sudo cat /etc/wsl.conf | grep -q "\[boot\]" > /dev/null 2>&1; then
        printInfo "Adding [boot] section with systemd=true to /etc/wsl.conf"
        sudo tee -a /etc/wsl.conf > /dev/null <<EOF
[boot]
systemd=true
EOF
    else
        printInfo "Adding systemd=true to existing [boot] section in /etc/wsl.conf"
        sudo sed -i '/\[boot\]/a systemd=true' /etc/wsl.conf
    fi
else
    printInfo "systemd=true already configured in /etc/wsl.conf"
fi

printInfo "Systemd tools installation complete"
printInfo "IMPORTANT: You must restart your WSL instance for systemd changes to take effect"