# `dev-basics`
A good basic base for general purpose development work.

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `essentials`
* Essential development tools: curl, wget, git, vim, nano, jq, yq, htop, rsync

### `python3`
* Install python3 + python3-pip
* PIP install commonly used python packages:
  * requests - HTTP library
  * numpy - Scientific computing
  * pandas - Data manipulation and analysis
  * matplotlib - Plotting library
  * jupyter - Interactive notebook environment
  * pytest - Testing framework
  * black - Code formatter
  * flake8 - Code linting
  * mypy - Static type checking

### `qol`
* Quality of life bits
* Symlink configuration picked up from your `wsl-builds.conf`:
```bash
CODE_HOME_SYMLINK=/home/me/code     # Symlink placed in your home dir on the WSL instance
CODE_HOME_TARGET=/mnt/c/code        # Location on your Windows host where you store code projects
```

## Build Arguments
* No additional arguments for this build
