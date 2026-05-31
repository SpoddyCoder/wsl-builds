#!/usr/bin/env bash

printInfo "Installing LangChain llama.cpp integration"

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

aptUpdateIfStale
sudo apt install -y cmake build-essential

_nvcc=""
if [[ -x "/usr/local/cuda/bin/nvcc" ]]; then
    _nvcc="/usr/local/cuda/bin/nvcc"
elif command -v nvcc >/dev/null 2>&1; then
    _nvcc="$(command -v nvcc)"
fi

if [[ -n "${_nvcc}" ]]; then
    if promptYesNo "Build llama-cpp-python with CUDA support"; then
        CMAKE_ARGS="-DGGML_CUDA=on" FORCE_CMAKE=1 pip install langchain-community llama-cpp-python
    else
        pip install langchain-community llama-cpp-python
    fi
else
    pip install langchain-community llama-cpp-python
fi

printInfo "LangChain llama.cpp integration version: $(python -c "from importlib.metadata import version; print(version('llama-cpp-python'))")"
printInfo "    conda activate agents"
printInfo "LangChain llama.cpp integration installed"
