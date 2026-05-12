#!/usr/bin/env bash

printInfo "Installing MySQL client"

aptUpdateIfStale
sudo apt install -y mysql-client

printInfo "MySQL client version: $(mysql --version)"

printInfo "MySQL client installed"
