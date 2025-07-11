#!/usr/bin/env bash

printInfo "Updating system"
sudo apt update
sudo apt full-upgrade
printInfo "System update complete" 