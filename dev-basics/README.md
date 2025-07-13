# `dev-basics`
A good basic base for general purpose development work.

## Requires
* `Ubuntu 22.04` or greater

## Build Options
### `essentials`
* Essential development tools: curl, wget, git, vim, nano, jq, yq, htop, rsync

### `python3`
* Install python3-pip (Python package installer)

### `qol`
* Quality of life bits
* Symlink configuration picked up from your `wsl-builds.conf`:
```bash
CODE_HOME_SYMLINK=/home/me/code     # Symlink placed in your home dir on the WSL instance
CODE_HOME_TARGET=/mnt/c/code        # Location on your Windows host where you store code projects
```

## Build Arguments
* No additional arguments for this build

---

## Installation Details & Additional Info

### `essentials`
Essential development tools for any development workflow:
* **git** - Version control system
* **rsync** - File synchronization tool
* **curl** - Command line tool for transferring data
* **htop** - Interactive process viewer

### `python3`
Complete Python 3 development environment:
* **python3** - Python 3 interpreter
* **pip3** - Python package installer
* **Essential Python packages:**
  * requests - HTTP library
  * numpy - Scientific computing
  * pandas - Data manipulation and analysis
  * matplotlib - Plotting library
  * jupyter - Interactive notebook environment
  * pytest - Testing framework
  * black - Code formatter
  * flake8 - Code linting
  * mypy - Static type checking
