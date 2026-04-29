#!/usr/bin/env bash

printInfo "Installing bats (bats-core)"
sudo apt update && sudo apt install -y bats

printInfo "bats installation complete"
