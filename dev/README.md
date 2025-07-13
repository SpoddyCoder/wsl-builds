# `dev`
A good basic base for general purpose development work.

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `essentials`
* Essential development tools: curl, wget, git, vim, nano, jq, yq, htop, rsync

### `qol`
* Quality of life bits
* Symlink configuration picked up from your `wsl-builds.conf`:
```bash
CODE_HOME_SYMLINK=/home/me/code     # Symlink placed in your home dir on the WSL instance
CODE_HOME_TARGET=/mnt/c/code        # Location on your Windows host where you store code projects
```

### `vscode`
* Launch VSCode to automatically install extensions for native Windows VSCode integration

### `cursor`
* Launch Cursor to automatically install extensions for native Windows Cursor integration
* Adds a bash alias to launch cursor when using `code`
* Install basic packages that Cursor editor likes to use (includes `tree`)

## Build Arguments
* No additional arguments for this build
