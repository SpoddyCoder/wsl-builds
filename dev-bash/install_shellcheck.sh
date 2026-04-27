#!/usr/bin/env bash

printInfo "Installing shellcheck"
sudo apt update && sudo apt install -y shellcheck

printInfo "shellcheck installation complete"
