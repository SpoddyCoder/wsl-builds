#!/usr/bin/env bash

printInfo "Installing X11 Apps"
aptUpdateIfStale
sudo apt install -y x11-apps
printInfo "X11 Apps installed"