# `system`
Basic system utilities and services for system admin and network file sharing.

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `update`
* Update apt & upgrade the system
* Recommended first step

### `qol`
* Set default user
* Add bash safety aliases
* Adds `change-hostname` function to .bashrc for changing WSL hostname
```bash
change-hostname <new-hostname>
```
* Add symlinks if defined in your `wsl-builds.conf`...
```bash
WIN_HOME_SYMLINK=/home/me/c-home    # Symlink placed in your home dir on the WSL instance
WIN_HOME_TARGET=/mnt/c/Users/me     # Location of your Windows host home dir on the WSL instance
```
* Enable `autoMemoryReclaim` in `/etc/wsl.conf`

### `x11`
* Install the X11-Apps package for native Windows GUI support

### `essentials`
* Install essential system utilities: htop, rsync

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

### `wslu`
* Install WSL Utilities (wslu) for enhanced WSL integration
* https://wslu.wedotstud.io/wslu/

## Build Arguments
* No additional arguments for this build

