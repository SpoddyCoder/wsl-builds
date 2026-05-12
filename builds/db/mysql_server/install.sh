#!/usr/bin/env bash

printInfo "Installing MySQL server"

sudo apt update
sudo apt install -y mysql-server

printInfo "MySQL server version: $(mysqld --version)"

if promptDisableSystemdUnitsOnBoot "Disable the MySQL systemd service from starting on boot" mysql.service; then
    printInfo "MySQL server is stopped and will not start automatically on boot"
fi

printInfo "MySQL server installed"
