#!/usr/bin/env bash

printInfo "Installing Sandbox hardening"

# shellcheck source=../../../src/builder/harden-git-auth.sh
source "${REPO_ROOT}/src/builder/harden-git-auth.sh"
warnHostGitCredentialsBeforeHarden

# shellcheck source=../../../src/builder/wsl-builds-conf-migrate.sh
source "${REPO_ROOT}/src/builder/wsl-builds-conf-migrate.sh"
migrateHostWslBuildsConfToHome

ensureWslConfSectionLine automount "enabled = false" "enabled = false"
ensureWslConfSectionLine automount "mountFsTab = false" "mountFsTab = false"
ensureWslConfSectionLine interop "enabled = false" "enabled = false"
ensureWslConfSectionLine interop "appendWindowsPath = false" "appendWindowsPath = false"

# shellcheck source=../../../src/builder/host-symlinks.sh
source "${REPO_ROOT}/src/builder/host-symlinks.sh"
promptRemoveHostHomeSymlinks

printWarning "IMPORTANT: Restart your WSL instance for wsl.conf changes to take effect (close all shells and IDE sessions; from PowerShell use wsl --list --running or wsl --shutdown if unsure)"

printWslBuildsConfMntPathReviewReminder

printInfo "Sandbox hardening installed"
