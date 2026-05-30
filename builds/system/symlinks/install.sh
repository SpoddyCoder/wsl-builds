#!/usr/bin/env bash

printInfo "Installing host symlinks"
# shellcheck source=../../../src/builder/host-symlinks.sh
source "${REPO_ROOT}/src/builder/host-symlinks.sh"
installHostSymlinksFromConf
printInfo "Host symlinks installed"
