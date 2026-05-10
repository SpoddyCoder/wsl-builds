#!/usr/bin/env bash

printInfo "Installing apt mirror switch"

sudo install -o root -g root -m 0755 "${BUILD_DIR}/apt-mirror-switch" /usr/local/bin/apt-mirror-switch

printInfo "apt mirror switch installed"
