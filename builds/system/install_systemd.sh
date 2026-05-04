#!/usr/bin/env bash

printInfo "Installing systemd tools"
sudo apt update
sudo apt install -y \
    systemd \
    systemd-sysv

ensureWslConfIniLine boot "systemd=true" "systemd=true"

printWarning "IMPORTANT: You must restart your WSL instance for systemd changes to take effect"

printInfo "Systemd tools installed"
