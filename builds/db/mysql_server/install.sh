#!/usr/bin/env bash

printInfo "Installing MySQL server"

sudo apt update
sudo apt install -y mysql-server

printInfo "MySQL server version: $(mysqld --version)"

if command -v systemctl >/dev/null 2>&1 && { [ -f /lib/systemd/system/mysql.service ] || [ -f /etc/systemd/system/mysql.service ]; }; then
    if promptYesNo "Disable the MySQL systemd service from starting on boot"; then
        sudo systemctl disable --now mysql
        printInfo "MySQL server is stopped and will not start automatically on boot"
    fi
fi

printInfo "MySQL server installed"
