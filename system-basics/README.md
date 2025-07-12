# `system-basics`
Basic system utilities and services for system admin and network file sharing.

## Requires
* `Ubuntu 22.04` or greater

## Build Options
### `smb`
* Install SMB/CIFS client tools for Windows file sharing
* Includes smbclient and cifs-utils for mounting Windows shares

### `nfs`
* Install NFS client tools for Unix/Linux file sharing
* Includes nfs-common for mounting NFS shares

### `fstab`
* Configure WSL to use /etc/fstab for automatic mounting
* Enables mountFsTab in `/etc/wsl.conf` (requires instance restart)

### `systemd`
* Install systemd tools and services
* Includes systemd and systemd-sysv
* Configures `/etc/wsl.conf` to enable systemd (requires instance restart)

## Build Arguments
* No additional arguments for this build

