#!/usr/bin/env bash

printInfo "Installing System updates"
aptUpdateRequired
sudo apt full-upgrade
printInfo "System updates installed"