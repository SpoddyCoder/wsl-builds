#!/usr/bin/env bash

printInfo "Installing X11 Apps"
sudo apt update
sudo apt install -y x11-apps
printInfo "X11 Apps installed"