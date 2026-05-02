#!/usr/bin/env bash

printInfo "Installing WSL fstab mounting"

# Configure WSL to use fstab mounting
if ! grep -q "mountFsTab = true" /etc/wsl.conf 2>/dev/null; then
    if ! grep -q "\[automount\]" /etc/wsl.conf 2>/dev/null; then
        printInfo "Adding [automount] section with mountFsTab = true to /etc/wsl.conf"
        sudo tee -a /etc/wsl.conf > /dev/null <<EOF
[automount]
mountFsTab = true
EOF
    else
        printInfo "Adding mountFsTab = true to existing [automount] section in /etc/wsl.conf"
        sudo sed -i '/\[automount\]/a mountFsTab = true' /etc/wsl.conf
    fi
else
    printInfo "mountFsTab = true already configured in /etc/wsl.conf"
fi

printWarning "IMPORTANT: You must restart your WSL instance for fstab changes to take effect"

printInfo "WSL fstab mounting installed"