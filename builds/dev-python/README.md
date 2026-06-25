# `dev-python`
Python development packages and tools

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `python3`
* Install python3 + python3-pip
* Basic Python development setup

### `pipx`
* Install [pipx](https://pipx.pypa.io/) via apt
* Runs `pipx ensurepath` so `~/.local/bin` is on PATH

### `uv`
* Install [uv](https://docs.astral.sh/uv/) via the official Astral install script
* Installs the `uv` binary to `~/.local/bin`

### `conda`
* Install Anaconda distribution for Python package management and environment support
  * https://www.anaconda.com/download#downloads
* NOTE: Select YES when asked about updating environment
* Disables auto_activate_base for cleaner shell experience

## Build Arguments
* No additional arguments for this build
