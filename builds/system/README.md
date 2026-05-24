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
* When login `PWD` is under `/mnt/c/Program Files/WSL2 Distro Manager`, interactive shells `cd` to `$HOME` (managed `wsl-builds:wsl-distro-manager-home` block in `~/.bashrc` / `~/.zshrc`)
* Installs `change-hostname` to `/usr/local/bin` for renaming the WSL instance (restart required)
```bash
sudo change-hostname <new-hostname>
```
* Add symlinks if defined in your `wsl-builds.conf`...
```bash
WIN_HOME_SYMLINK=/home/me/c-home    # Symlink placed in your home dir on the WSL instance
WIN_HOME_TARGET=/mnt/c/Users/me     # Location of your Windows host home dir on the WSL instance
```

### `apt-mirror-switch`
* Installs `apt-mirror-switch` on `PATH` for switching Ubuntu **archive/security** APT mirrors (`/etc/apt/sources.list` or `sources.list.d/ubuntu.sources`)
```bash
apt-mirror-switch                  # usage + mirror list + current mirror (classification)
sudo apt-mirror-switch canonical    # Canonical archive/security hosts
sudo apt-mirror-switch uni-of-kent  # Uni of Kent mirrorservice mirror
```
* Restoring `canonical` when using **DEB822** `ubuntu.sources` requires `python3` on the distro

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

