#!/usr/bin/env bash

SCRIPT_DIR="devops"

if [ -n "$INSTALL_TERRAFORM" ]; then
    if ! isComponentInstalled "terraform" "$@"; then
        # shellcheck source=devops/install_terraform.sh
        source ${SCRIPT_DIR}/install_terraform.sh
        recordComponentSuccess "terraform"
    else
        warnComponentAlreadyInstalled "terraform"
    fi
fi

if [ -n "$INSTALL_PACKER" ]; then
    if ! isComponentInstalled "packer" "$@"; then
        # shellcheck source=devops/install_packer.sh
        source ${SCRIPT_DIR}/install_packer.sh
        recordComponentSuccess "packer"
    else
        warnComponentAlreadyInstalled "packer"
    fi
fi

if [ -n "$INSTALL_KUBECTL" ]; then
    if ! isComponentInstalled "kubectl" "$@"; then
        # shellcheck source=devops/install_kubectl.sh
        source ${SCRIPT_DIR}/install_kubectl.sh
        recordComponentSuccess "kubectl"
    else
        warnComponentAlreadyInstalled "kubectl"
    fi
fi

if [ -n "$INSTALL_K9S" ]; then
    if ! isComponentInstalled "k9s" "$@"; then
        # shellcheck source=devops/install_k9s.sh
        source ${SCRIPT_DIR}/install_k9s.sh
        recordComponentSuccess "k9s"
    else
        warnComponentAlreadyInstalled "k9s"
    fi
fi

if [ -n "$INSTALL_DOCKER" ]; then
    if ! isComponentInstalled "docker" "$@"; then
        # shellcheck source=devops/install_docker.sh
        source ${SCRIPT_DIR}/install_docker.sh
        recordComponentSuccess "docker"
    else
        warnComponentAlreadyInstalled "docker"
    fi
fi

if [ -n "$INSTALL_DOCKER_DESKTOP" ]; then
    # shellcheck source=devops/install_docker_desktop.sh
    source ${SCRIPT_DIR}/install_docker_desktop.sh
    # nothing to install on the WSL instance, just install on the Windows host for best perfomance
fi
