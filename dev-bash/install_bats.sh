#!/usr/bin/env bash

printInfo "Installing bats (bats-core)"
sudo apt update && sudo apt install -y bats

printInfo "bats version: $(bats --version)"
printInfo "bats (bats-core) installed"
