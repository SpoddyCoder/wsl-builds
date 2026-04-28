#!/usr/bin/env bash

printInfo "Installing PostgreSQL server"

sudo apt install -y postgresql postgresql-contrib

# Verify installation
printInfo "PostgreSQL server installed successfully"
printInfo "psql version: $(psql --version)"
printInfo "Clusters:"
pg_lsclusters
