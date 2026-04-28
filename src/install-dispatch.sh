#!/usr/bin/env bash
# Sourced by each `<build-dir>/install.sh` (which `build.sh` sources). Do not wrap this
# loop in a function: SIGINT during `source …/install_<comp>.sh` + nested function frames
# has triggered Bash `pop_var_context` noise on some versions.
#
# Inherited when sourced: `VALID_INSTALL_COMPONENTS`, `BUILD_DIR`, `INSTALL_*`, and `$@`
# from `build.sh` (positional args propagate through the source chain).

IFS=',' read -r -a _ric_components <<< "$VALID_INSTALL_COMPONENTS"
for _ric_comp in "${_ric_components[@]}"; do
    _ric_underscore="${_ric_comp//-/_}"
    _ric_var_name="INSTALL_${_ric_underscore^^}"
    if [[ -z "${!_ric_var_name:-}" ]]; then
        continue
    fi
    if ! isComponentInstalled "${_ric_comp}" "$@"; then
        _ric_installer="${BUILD_DIR}/install_${_ric_underscore}.sh"
        # shellcheck source=/dev/null # install_<component>.sh resolved from $VALID_INSTALL_COMPONENTS
        source "${_ric_installer}"
        recordComponentSuccess "${_ric_comp}"
    else
        warnComponentAlreadyInstalled "${_ric_comp}"
    fi
done
unset -v _ric_comp _ric_underscore _ric_var_name _ric_installer _ric_components 2>/dev/null || true
