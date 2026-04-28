#!/usr/bin/env bash
# Loop VALID_INSTALL_COMPONENTS and source install_<name>.sh when INSTALL_<NAME> is set.
#
# No `local` here: interrupting (e.g. SIGINT) inside a sourced installer while function-local
# scopes are active has triggered Bash "pop_var_context" noise.

runInstallComponents() {
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
}
