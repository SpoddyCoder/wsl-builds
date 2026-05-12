#!/usr/bin/env bash

printInfo "Installing PostgreSQL server"

sudo apt update
sudo apt install -y postgresql postgresql-contrib

printInfo "psql version: $(psql --version)"
printInfo "PostgreSQL clusters:"
pg_lsclusters

if isSystemdManagerRunning && [ -f /lib/systemd/system/postgresql@.service ]; then
    _pg_ls_line=$(pg_lsclusters --no-header | head -n1)
    if [ -n "${_pg_ls_line}" ]; then
        _pg_ver=$(awk '{ print $1 }' <<<"${_pg_ls_line}")
        _pg_cluster=$(awk '{ print $2 }' <<<"${_pg_ls_line}")
        _pg_unit="postgresql@${_pg_ver}-${_pg_cluster}"
        if promptYesNo "Disable the PostgreSQL systemd service (${_pg_unit}) from starting on boot"; then
            sudo systemctl disable --now "${_pg_unit}"
            printInfo "PostgreSQL server is stopped and will not start automatically on boot"
        fi
    fi
fi

printInfo "PostgreSQL server installed"
