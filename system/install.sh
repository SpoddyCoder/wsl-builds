#!/usr/bin/env bash

SCRIPT_DIR="system"

if [ ! -z $INSTALL_SMB ] && ! (smbclient --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_smb.sh
    recordComponentSuccess "smb"
fi

if [ ! -z $INSTALL_NFS ] && ! (showmount --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_nfs.sh
    recordComponentSuccess "nfs"
fi

if [ ! -z $INSTALL_FSTAB ]; then
    source ${SCRIPT_DIR}/install_fstab.sh
    recordComponentSuccess "fstab"
fi

if [ ! -z $INSTALL_SYSTEMD ] && ! (systemctl --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_systemd.sh
    recordComponentSuccess "systemd"
fi

if [ ! -z $INSTALL_ESSENTIALS ]; then
    source ${SCRIPT_DIR}/install_essentials.sh
    recordComponentSuccess "essentials"
fi

if [ ! -z $INSTALL_WSLU ] && ! (wslusc --version) > /dev/null 2>&1; then
    source ${SCRIPT_DIR}/install_wslu.sh
    recordComponentSuccess "wslu"
fi
