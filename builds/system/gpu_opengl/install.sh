#!/usr/bin/env bash

printInfo "Installing GPU OpenGL"

aptUpdateIfStale
sudo apt install -y mesa-utils

printInfo "Checking OpenGL renderer (Mesa / WSLg)"

current_renderer="(unavailable)"
if _gpu_gl_line="$(glxinfo 2>/dev/null | grep -F 'OpenGL renderer string:')"; then
    current_renderer="${_gpu_gl_line#OpenGL renderer string: }"
fi
printInfo "Current OpenGL renderer: ${current_renderer}"

d3d12_renderer=""
if _gpu_gl_line="$(GALLIUM_DRIVER=d3d12 glxinfo 2>/dev/null | grep -F 'OpenGL renderer string:')"; then
    d3d12_renderer="${_gpu_gl_line#OpenGL renderer string: }"
fi

if [[ -z "${d3d12_renderer}" || "${d3d12_renderer}" == *llvmpipe* || "${d3d12_renderer}" != *D3D12* ]]; then
    printWarning "GALLIUM_DRIVER=d3d12 did not select a D3D12 GPU renderer"
    if [[ -n "${d3d12_renderer}" ]]; then
        printWarning "Probe result: ${d3d12_renderer}"
    fi
    printWarning "Needs WSLg, a Windows GPU driver with D3D12, and a Mesa build that includes the d3d12 Gallium driver"
    printInfo "GPU OpenGL skipped"
    return 0
fi

printInfo "D3D12 OpenGL renderer: ${d3d12_renderer}"

rc_body='export GALLIUM_DRIVER=d3d12'
if promptYesNoDefaultNo "Set MESA_D3D12_DEFAULT_ADAPTER_NAME (hybrid / multi-GPU)"; then
    printf '%s' "Adapter name substring (e.g. NVIDIA or Intel): "
    read -r adapter_name || adapter_name=""
    if [[ -n "${adapter_name}" ]]; then
        rc_body+=$'\n'"export MESA_D3D12_DEFAULT_ADAPTER_NAME=$(printf '%q' "${adapter_name}")"
    else
        printWarning "Empty adapter name; skipping MESA_D3D12_DEFAULT_ADAPTER_NAME"
    fi
fi

replaceManagedShellRcRegion gpu-opengl "${rc_body}"

export GALLIUM_DRIVER=d3d12
printInfo "Open a new terminal or run: source ~/.bashrc"
printInfo "Verify with: glxinfo | grep \"OpenGL renderer\""

printInfo "GPU OpenGL installed"
