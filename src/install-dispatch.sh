#!/usr/bin/env bash
# Loop VALID_INSTALL_COMPONENTS and source install_<name>.sh when INSTALL_<NAME> is set.

runInstallComponents() {
    local comp underscore installer var_name
    IFS=',' read -r -a components <<< "$VALID_INSTALL_COMPONENTS"
    for comp in "${components[@]}"; do
        underscore="${comp//-/_}"
        var_name="INSTALL_${underscore^^}"
        if [[ -z "${!var_name:-}" ]]; then
            continue
        fi
        if ! isComponentInstalled "${comp}" "$@"; then
            installer="${BUILD_DIR}/install_${underscore}.sh"
            # shellcheck source=/dev/null # install_<component>.sh resolved from $VALID_INSTALL_COMPONENTS
            source "${installer}"
            recordComponentSuccess "${comp}"
        else
            warnComponentAlreadyInstalled "${comp}"
        fi
    done
}
