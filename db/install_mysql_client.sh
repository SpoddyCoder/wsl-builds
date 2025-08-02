#!/usr/bin/env bash

printInfo "Installing MySQL client"

sudo apt install -y mysql-client

# Verify installation
printInfo "MySQL client installed successfully"
printInfo "MySQL client version: $(mysql --version)"

