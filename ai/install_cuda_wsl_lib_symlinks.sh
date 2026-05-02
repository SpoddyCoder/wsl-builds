#!/usr/bin/env bash

printInfo "Installing CUDA WSL lib symlinks"

wsl_lib=/usr/lib/wsl/lib
if [[ ! -d "$wsl_lib" ]]; then
    printWarning "/usr/lib/wsl/lib not found; skipping"
    printInfo "CUDA WSL lib symlinks skipped"
    return 0
fi

shopt -s nullglob
versioned_candidates=("$wsl_lib"/libcuda.so.1.*)
shopt -u nullglob

versioned_basename=
for path in "${versioned_candidates[@]}"; do
    base=$(basename "$path")
    if [[ "$base" == "libcuda.so.1" ]]; then
        continue
    fi
    if [[ -f "$path" && ! -L "$path" ]]; then
        versioned_basename=$base
        break
    fi
done

if [[ -z "$versioned_basename" ]]; then
    printWarning "No versioned libcuda.so.1.* file in ${wsl_lib}; skipping"
    printInfo "CUDA WSL lib symlinks skipped"
    return 0
fi

versioned_path="${wsl_lib}/${versioned_basename}"
so1="${wsl_lib}/libcuda.so.1"
so="${wsl_lib}/libcuda.so"

resolve_so1=$(readlink -f "$so1" 2>/dev/null || true)
resolve_ver=$(readlink -f "$versioned_path" 2>/dev/null || true)

if [[ -n "$resolve_so1" && "$resolve_so1" == "$resolve_ver" ]] && [[ -L "$so" && "$(readlink "$so")" == "libcuda.so.1" ]]; then
    printInfo "CUDA WSL lib symlinks installed"
    return 0
fi

printInfo "Recreating libcuda.so symlinks for ${versioned_basename}"
(
    cd "$wsl_lib" || exit 1
    sudo rm -f libcuda.so libcuda.so.1
    sudo ln -s "$versioned_basename" libcuda.so.1
    sudo ln -s libcuda.so.1 libcuda.so
)
sudo ldconfig

printInfo "CUDA WSL lib symlinks installed"
