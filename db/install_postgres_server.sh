#!/usr/bin/env bash

printInfo "Installing PostgreSQL server"

sudo apt update
sudo apt install -y postgresql postgresql-contrib

printInfo "psql version: $(psql --version)"
printInfo "PostgreSQL clusters:"
pg_lsclusters

printInfo "PostgreSQL server installed"
