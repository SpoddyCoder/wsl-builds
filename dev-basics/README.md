# `dev-basics`
A good basic base for general purpose development work.

## Requires
* `Ubuntu 22.04` or greater

## Build Options
### `essentials`
* All the basics: git, rsync, curl, htop etc

### `python3`
* Install python3, pip and essential python3 packages

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

## Examples

### General Development Setup
```bash
./build.sh dev-basics essentials,python3
```

### Just the Basics
```bash
./build.sh dev-basics essentials
```

