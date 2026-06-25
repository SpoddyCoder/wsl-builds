#!/usr/bin/env bash

printInfo "Installing pipx"

printInfo "Installing dependencies"
aptUpdateIfStale
sudo apt install -y pipx

printInfo "Ensuring pipx is on PATH"
pipx ensurepath

printInfo "pipx version: $(pipx --version)"

printInfo "pipx installed"
