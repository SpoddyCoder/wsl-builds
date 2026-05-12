#!/usr/bin/env bash

printInfo "Installing PostgreSQL client"

aptUpdateIfStale
sudo apt install -y postgresql-client

printInfo "psql version: $(psql --version)"

printInfo "PostgreSQL client installed"
