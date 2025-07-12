# `biscuit`
This is our base install, with very little extra added.

## Requires
* `Ubuntu 22.04` or greater

## Build Options
### `update`
* Update apt & upgrade the system
* Recommended first step

### `qol`
* Set default user, add symlinks if defined, add bash safety aliases
* Symlink definitions picked up from your `wsl-builds.conf`, see below

### `x11`
* Install the X11-Apps package for native Windows GUI support

### `vscode`
* Install the VSCode extensions for native Windows VSCode integration

### `cursor`
* Adds a bash alias to launch cursor when using `code .`
* Install basic packages that Cursor editor likes to use (includes `tree`)

## Build Arguments
* No additional arguments for this build

## Config
You can optionally add these to your `wsl-builds.conf` and they will be used during the `qol` installation...
```
WIN_HOME=/mnt/c/Users/me            # Location of your Windows host home dir on the WSL instance
WIN_HOME_SYMLINK=/home/me/c-home    # symlink placed in the home dir of the WSL instance
CODE_HOME=/mnt/c/code               # Location on your Windows host where you store code project
CODE_HOME_SYMLINK=/home/me/code     # symlink placed in the home dir of the WSL instance
```


