#!/usr/bin/env bash

SCRIPT_DIR="system-basics"

if [ ! -z $INSTALL_SMB ] && ! (smbclient --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_smb.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_NFS ] && ! (showmount --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_nfs.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_FSTAB ]; then
    source ${SCRIPT_DIR}/install_fstab.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_SYSTEMD ] && ! (systemctl --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_systemd.sh
    BUILD_UPDATED=true
fi

if [ ! -z $INSTALL_ESSENTIALS ]; then
    source ${SCRIPT_DIR}/install_essentials.sh
    BUILD_UPDATED=true
fi
