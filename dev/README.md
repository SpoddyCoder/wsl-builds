# `dev`
A good basic base for general purpose development work.

## Requires
* `Ubuntu 22.04` or greater

## Build Components

### `vscode`
* Launch VSCode to automatically install extensions for native Windows VSCode integration
* See the [VSCode section](../README.md#vscode-integration) of the main README for more info.

### `cursor`
* Launch Cursor to automatically install extensions for native Windows Cursor integration
* Adds a bash alias to launch cursor when using `code`
* Install basic packages that Cursor editor likes to use (includes `tree`)
* See the [Cursor section](../README.md#cursor-integration) of the main README for more info.

### `qol`
* Quality of life bits
* Symlink configuration picked up from your `wsl-builds.conf`:
```bash
CODE_HOME_SYMLINK=/home/me/code     # Symlink placed in your home dir on the WSL instance
CODE_HOME_TARGET=/mnt/c/code        # Location on your Windows host where you store code projects
```

### `essentials`
* Essential dev tools: `curl`, `wget`, `git`, `vim`, `nano`, `jq`, `yq`
* Optional global git config picked up from your `wsl-builds.conf` (each key is independent; unset keys are skipped):
```bash
GIT_CREDENTIALS_HELPER="/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
GIT_USER_NAME="me"
GIT_USER_EMAIL="my@email.com"
GIT_PULL_REBASE=false
```
* Using the credntials helper from the host machine can be convenient to avoid having to setup auth on each WSL instance.
* See the [Git section](../README.md#git-integration) of the main README for more info.

## Build Arguments
* No additional arguments for this build
