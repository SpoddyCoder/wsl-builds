#!/usr/bin/env bash

printInfo "Installing llama.cpp"

_llama_src="${LLAMA_CPP_SRC_DIR:-$HOME/llama.cpp}"
_llama_prefix="${LLAMA_CPP_INSTALL_PREFIX:-$HOME/.local}"
_llama_build="${_llama_src}/build"

printInfo "Installing build dependencies"
aptUpdateIfStale
sudo apt install -y git build-essential cmake ninja-build pkg-config libssl-dev

if [[ -d "${_llama_src}/.git" ]]; then
    printInfo "Updating llama.cpp source tree"
    git -C "${_llama_src}" pull --ff-only
else
    printInfo "Cloning llama.cpp"
    mkdir -p "$(dirname "${_llama_src}")"
    git clone https://github.com/ggml-org/llama.cpp.git "${_llama_src}"
fi

_cmake_cuda=()
_nvcc=""
if [[ -x "/usr/local/cuda/bin/nvcc" ]]; then
    _nvcc="/usr/local/cuda/bin/nvcc"
elif command -v nvcc >/dev/null 2>&1; then
    _nvcc="$(command -v nvcc)"
fi
if [[ -n "${_nvcc}" ]]; then
    printInfo "Configuring CMake with CUDA (nvcc: ${_nvcc})"
    _cmake_cuda=( -DGGML_CUDA=ON )
    PATH="$(dirname "${_nvcc}"):${PATH}"
    export PATH
else
    printInfo "Configuring CMake for CPU only (no nvcc in PATH; install a cuda* component for GPU)"
fi

printInfo "Configuring and building llama.cpp (this may take a while)"
cmake -S "${_llama_src}" -B "${_llama_build}" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${_llama_prefix}" \
    -DCMAKE_INSTALL_RPATH="${_llama_prefix}/lib" \
    "${_cmake_cuda[@]}"
cmake --build "${_llama_build}" -j"$(nproc)"
cmake --install "${_llama_build}"

replaceManagedShellRcRegion llama-cpp "$(printf "export PATH=\"%s/bin:\${PATH}\"\nexport LD_LIBRARY_PATH=\"%s/lib\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}\"\n" "${_llama_prefix}" "${_llama_prefix}")"

# Same as the rc block: verify and version-print without requiring a new login shell
export LD_LIBRARY_PATH="${_llama_prefix}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

_llama_ver_bin=""
if [[ -x "${_llama_prefix}/bin/llama-cli" ]]; then
    _llama_ver_bin="${_llama_prefix}/bin/llama-cli"
elif [[ -x "${_llama_prefix}/bin/main" ]]; then
    _llama_ver_bin="${_llama_prefix}/bin/main"
fi
if [[ -n "${_llama_ver_bin}" ]]; then
    printInfo "llama.cpp version: $("${_llama_ver_bin}" --version 2>&1 | head -n1)"
fi

printInfo "llama.cpp installed"
