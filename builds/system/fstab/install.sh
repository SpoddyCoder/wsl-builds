#!/usr/bin/env bash

printInfo "Installing WSL fstab mounting"

ensureWslConfIniLine automount "mountFsTab = true" "mountFsTab = true"

printWarning "IMPORTANT: You must restart your WSL instance for fstab changes to take effect"

printInfo "WSL fstab mounting installed"
