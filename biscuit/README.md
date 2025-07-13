# `biscuit`
This is our base install, with very little extra added.

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `update`
* Update apt & upgrade the system
* Recommended first step

### `qol`
* Set default user, add symlinks if defined, add bash safety aliases
* Adds `change-hostname` function to .bashrc for changing WSL hostname
```bash
change-hostname <new-hostname>
```
* Symlink definitions picked up from your `wsl-builds.conf`...
```bash
WIN_HOME_SYMLINK=/home/me/c-home    # Symlink placed in your home dir on the WSL instance
WIN_HOME_TARGET=/mnt/c/Users/me     # Location of your Windows host home dir on the WSL instance
```

### `x11`
* Install the X11-Apps package for native Windows GUI support

## Build Arguments
* No additional arguments for this build

