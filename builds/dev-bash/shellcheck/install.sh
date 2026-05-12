#!/usr/bin/env bash

printInfo "Installing shellcheck"
aptUpdateIfStale
sudo apt install -y shellcheck

printInfo "shellcheck version: $(shellcheck --version | sed -n 's/^version: //p')"
printInfo "shellcheck installed"
