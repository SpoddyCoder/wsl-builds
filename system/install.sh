#!/usr/bin/env bash

SCRIPT_DIR="system"

if [ -n "$INSTALL_UPDATE" ]; then
    if ! isComponentInstalled "update" "$@"; then
        # shellcheck source=system/install_update.sh
        source ${SCRIPT_DIR}/install_update.sh
        recordComponentSuccess "update"
    else
        warnComponentAlreadyInstalled "update"
    fi
fi

if [ -n "$INSTALL_QOL" ]; then
    if ! isComponentInstalled "qol" "$@"; then
        # shellcheck source=system/install_qol.sh
        source ${SCRIPT_DIR}/install_qol.sh
        recordComponentSuccess "qol"
    else
        warnComponentAlreadyInstalled "qol"
    fi
fi

if [ -n "$INSTALL_X11" ]; then
    if ! isComponentInstalled "x11" "$@"; then
        # shellcheck source=system/install_x11.sh
        source ${SCRIPT_DIR}/install_x11.sh
        recordComponentSuccess "x11"
    else
        warnComponentAlreadyInstalled "x11"
    fi
fi

if [ -n "$INSTALL_SMB" ]; then
    if ! isComponentInstalled "smb" "$@"; then
        # shellcheck source=system/install_smb.sh
        source ${SCRIPT_DIR}/install_smb.sh
        recordComponentSuccess "smb"
    else
        warnComponentAlreadyInstalled "smb"
    fi
fi

if [ -n "$INSTALL_NFS" ]; then
    if ! isComponentInstalled "nfs" "$@"; then
        # shellcheck source=system/install_nfs.sh
        source ${SCRIPT_DIR}/install_nfs.sh
        recordComponentSuccess "nfs"
    else
        warnComponentAlreadyInstalled "nfs"
    fi
fi

if [ -n "$INSTALL_FSTAB" ]; then
    if ! isComponentInstalled "fstab" "$@"; then
        # shellcheck source=system/install_fstab.sh
        source ${SCRIPT_DIR}/install_fstab.sh
        recordComponentSuccess "fstab"
    else
        warnComponentAlreadyInstalled "fstab"
    fi
fi

if [ -n "$INSTALL_SYSTEMD" ]; then
    if ! isComponentInstalled "systemd" "$@"; then
        # shellcheck source=system/install_systemd.sh
        source ${SCRIPT_DIR}/install_systemd.sh
        recordComponentSuccess "systemd"
    else
        warnComponentAlreadyInstalled "systemd"
    fi
fi

if [ -n "$INSTALL_ESSENTIALS" ]; then
    if ! isComponentInstalled "essentials" "$@"; then
        # shellcheck source=system/install_essentials.sh
        source ${SCRIPT_DIR}/install_essentials.sh
        recordComponentSuccess "essentials"
    else
        warnComponentAlreadyInstalled "essentials"
    fi
fi

if [ -n "$INSTALL_WSLU" ]; then
    if ! isComponentInstalled "wslu" "$@"; then
        # shellcheck source=system/install_wslu.sh
        source ${SCRIPT_DIR}/install_wslu.sh
        recordComponentSuccess "wslu"
    else
        warnComponentAlreadyInstalled "wslu"
    fi
fi
