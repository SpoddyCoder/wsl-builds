#!/usr/bin/env bash

printInfo "Installing LangChain"

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

pip install -U langchain

if promptYesNo "Install LangChain Ollama integration (langchain-ollama)"; then
    if ! command -v ollama >/dev/null 2>&1; then
        printWarning "Ollama is not installed"
    fi
    pip install langchain-ollama
fi

if promptYesNo "Install LangChain llama.cpp integration (langchain-community and llama-cpp-python)"; then
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
fi

printInfo "LangChain version: $(python -c "from importlib.metadata import version; print(version('langchain'))")"
printInfo "    conda activate agents"
printInfo "LangChain installed"
