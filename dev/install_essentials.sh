#!/usr/bin/env bash

printInfo "Installing Dev essentials"
sudo apt update
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    jq \
    yq

printInfo "Dev essentials installed"