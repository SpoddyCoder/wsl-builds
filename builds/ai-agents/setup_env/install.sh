#!/usr/bin/env bash

printInfo "Installing Setup env"

_conda_sh="${HOME}/anaconda3/etc/profile.d/conda.sh"
if [[ ! -f "${_conda_sh}" ]]; then
    printError "Anaconda conda not found; run: ./wsl-builder.sh dev-python conda"
    exit 1
fi
# shellcheck source=/dev/null # conda.sh is provided by Anaconda at runtime
source "${_conda_sh}"

if conda env list | grep -qE '^\s*agents\s'; then
    if promptYesNoDefaultNo "Recreate existing agents conda environment"; then
        conda env remove --name agents -y
    fi
fi

if ! conda env list | grep -qE '^\s*agents\s'; then
    conda create --name agents python=3.11 -y
fi

conda activate agents

pip install -U python-dotenv httpx jupyter pydantic

printInfo "Setup env version: $(python --version)"
printInfo "    conda activate agents"
printInfo "Setup env installed"
