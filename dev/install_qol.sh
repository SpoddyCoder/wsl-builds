#!/usr/bin/env bash

printInfo "Installing dev QoL bits"

# Create code home symlink if configured
if [ ! -L ${CODE_HOME_SYMLINK} ] && [ ! -z ${CODE_HOME_TARGET} ]; then
    printInfo "Creating code home symlink: ${CODE_HOME_SYMLINK} -> ${CODE_HOME_TARGET}"
    ln -s ${CODE_HOME_TARGET} ${CODE_HOME_SYMLINK}
else
    if [ -L ${CODE_HOME_SYMLINK} ]; then
        printInfo "Code home symlink already exists: ${CODE_HOME_SYMLINK}"
    else
        printInfo "CODE_HOME_TARGET not configured, skipping code home symlink creation"
    fi
fi

printInfo "dev QoL installation complete" 