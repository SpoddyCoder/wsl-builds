#!/usr/bin/env bash

printInfo "Configuring WSL fstab mounting"

# Configure WSL to use fstab mounting
if ! sudo cat /etc/wsl.conf | grep -q "mountFsTab = true" > /dev/null 2>&1; then
    if ! sudo cat /etc/wsl.conf | grep -q "\[automount\]" > /dev/null 2>&1; then
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

printInfo "WSL fstab mounting configuration complete"
printInfo "IMPORTANT: You must restart your WSL instance for fstab changes to take effect" 