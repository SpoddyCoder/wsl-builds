#!/usr/bin/env bash

SCRIPT_DIR="system"

if [ ! -z $INSTALL_UPDATE ]; then
    if ! isComponentInstalled "update" "$@"; then
        source ${SCRIPT_DIR}/install_update.sh
        recordComponentSuccess "update"
    else
        warnComponentAlreadyInstalled "update"
    fi
fi

if [ ! -z $INSTALL_QOL ]; then
    if ! isComponentInstalled "qol" "$@"; then
        source ${SCRIPT_DIR}/install_qol.sh
        recordComponentSuccess "qol"
    else
        warnComponentAlreadyInstalled "qol"
    fi
fi

if [ ! -z $INSTALL_X11 ]; then
    if ! isComponentInstalled "x11" "$@"; then
        source ${SCRIPT_DIR}/install_x11.sh
        recordComponentSuccess "x11"
    else
        warnComponentAlreadyInstalled "x11"
    fi
fi

if [ ! -z $INSTALL_SMB ]; then
    if ! isComponentInstalled "smb" "$@"; then
        source ${SCRIPT_DIR}/install_smb.sh
        recordComponentSuccess "smb"
    else
        warnComponentAlreadyInstalled "smb"
    fi
fi

if [ ! -z $INSTALL_NFS ]; then
    if ! isComponentInstalled "nfs" "$@"; then
        source ${SCRIPT_DIR}/install_nfs.sh
        recordComponentSuccess "nfs"
    else
        warnComponentAlreadyInstalled "nfs"
    fi
fi

if [ ! -z $INSTALL_FSTAB ]; then
    if ! isComponentInstalled "fstab" "$@"; then
        source ${SCRIPT_DIR}/install_fstab.sh
        recordComponentSuccess "fstab"
    else
        warnComponentAlreadyInstalled "fstab"
    fi
fi

if [ ! -z $INSTALL_SYSTEMD ]; then
    if ! isComponentInstalled "systemd" "$@"; then
        source ${SCRIPT_DIR}/install_systemd.sh
        recordComponentSuccess "systemd"
    else
        warnComponentAlreadyInstalled "systemd"
    fi
fi

if [ ! -z $INSTALL_ESSENTIALS ]; then
    if ! isComponentInstalled "essentials" "$@"; then
        source ${SCRIPT_DIR}/install_essentials.sh
        recordComponentSuccess "essentials"
    else
        warnComponentAlreadyInstalled "essentials"
    fi
fi

if [ ! -z $INSTALL_WSLU ]; then
    if ! isComponentInstalled "wslu" "$@"; then
        source ${SCRIPT_DIR}/install_wslu.sh
        recordComponentSuccess "wslu"
    else
        warnComponentAlreadyInstalled "wslu"
    fi
fi
