#!/usr/bin/env bash

printInfo "Installing Dev essentials"
aptUpdateIfStale
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    jq \
    yq

if [ -n "${GIT_USER_NAME:-}" ]; then
    printInfo "Configuring git user.name from wsl-builds.conf: ${GIT_USER_NAME}"
    git config --global user.name "${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
    printInfo "Configuring git user.email from wsl-builds.conf: ${GIT_USER_EMAIL}"
    git config --global user.email "${GIT_USER_EMAIL}"
fi
if [ -n "${GIT_CREDENTIALS_HELPER:-}" ]; then
    printInfo "Configuring git credential.helper from wsl-builds.conf: ${GIT_CREDENTIALS_HELPER}"
    git config --global credential.helper "${GIT_CREDENTIALS_HELPER}"
fi
if [ -n "${GIT_PULL_REBASE:-}" ]; then
    printInfo "Configuring git pull.rebase from wsl-builds.conf: ${GIT_PULL_REBASE}"
    git config --global pull.rebase "${GIT_PULL_REBASE}"
fi
if [ -n "${GIT_INIT_DEFAULT_BRANCH:-}" ]; then
    printInfo "Configuring git init.defaultBranch from wsl-builds.conf: ${GIT_INIT_DEFAULT_BRANCH}"
    git config --global init.defaultBranch "${GIT_INIT_DEFAULT_BRANCH}"
fi

printInfo "Dev essentials installed"