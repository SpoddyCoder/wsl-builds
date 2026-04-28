#!/usr/bin/env bash

printInfo "Installing PostgreSQL client"

sudo apt install -y postgresql-client

# Verify installation
printInfo "PostgreSQL client installed successfully"
printInfo "psql version: $(psql --version)"
