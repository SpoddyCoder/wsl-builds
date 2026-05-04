#!/usr/bin/env bash
# Sourced by each `<build-dir>/install.sh` (which `wsl-builder.sh` sources). Do not wrap this
# loop in a function: SIGINT during `source …/install_<comp>.sh` + nested function frames
# has triggered Bash `pop_var_context` noise on some versions.
#
# Inherited when sourced: `VALID_INSTALL_COMPONENTS`, `BUILD_DIR`, `INSTALL_*`, and `$@`
# from `wsl-builder.sh` (positional args propagate through the source chain).

IFS=',' read -r -a dispatch_install_component_names <<< "$VALID_INSTALL_COMPONENTS"
for dispatch_install_component_name in "${dispatch_install_component_names[@]}"; do
    dispatch_install_component_slug="${dispatch_install_component_name//-/_}"
    dispatch_install_toggle_var_name="INSTALL_${dispatch_install_component_slug^^}"
    if [[ -z "${!dispatch_install_toggle_var_name:-}" ]]; then
        continue
    fi
    if ! isComponentInstalled "${dispatch_install_component_name}" "$@"; then
        dispatch_install_component_script_path="${BUILD_DIR}/install_${dispatch_install_component_slug}.sh"
        # shellcheck source=/dev/null # install_<component>.sh resolved from $VALID_INSTALL_COMPONENTS
        source "${dispatch_install_component_script_path}"
        recordComponentSuccess "${dispatch_install_component_name}"
    else
        warnComponentAlreadyInstalled "${dispatch_install_component_name}"
    fi
done
unset -v dispatch_install_component_name dispatch_install_component_slug dispatch_install_toggle_var_name dispatch_install_component_script_path dispatch_install_component_names 2>/dev/null || true
