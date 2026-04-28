#!/usr/bin/env bash

printInfo "Installing MySQL server"

sudo apt install -y mysql-server

# Verify installation
printInfo "MySQL server installed successfully"
printInfo "MySQL server version: $(mysqld --version)"
