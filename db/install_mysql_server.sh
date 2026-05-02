#!/usr/bin/env bash

printInfo "Installing MySQL server"

sudo apt update
sudo apt install -y mysql-server

printInfo "MySQL server version: $(mysqld --version)"

printInfo "MySQL server installed"
