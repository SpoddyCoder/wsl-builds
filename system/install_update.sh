#!/usr/bin/env bash

printInfo "Installing System updates"
sudo apt update
sudo apt full-upgrade
printInfo "System updates installed"