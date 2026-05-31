#!/usr/bin/env bash

printInfo "Installing MCP"

_conda_sh="${HOME}/anaconda3/etc/profile.d/conda.sh"
if [[ ! -f "${_conda_sh}" ]]; then
    printError "Anaconda conda not found; run: ./wsl-builder.sh dev-python conda"
    exit 1
fi
# shellcheck source=/dev/null # conda.sh is provided by Anaconda at runtime
source "${_conda_sh}"

if ! conda env list | grep -qE '^\s*agents\s'; then
    printError "Conda environment agents not found; run: ./wsl-builder.sh ai-agents setup-env"
    exit 1
fi

conda activate agents

pip install -U mcp

printInfo "MCP version: $(python -c "from importlib.metadata import version; print(version('mcp'))")"
printInfo "    conda activate agents"
printInfo "MCP installed"
