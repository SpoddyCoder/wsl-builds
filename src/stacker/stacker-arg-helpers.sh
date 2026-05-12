#!/usr/bin/env bash
# Stacker arg and listing helpers (mirrors src/builder/arg-helpers.sh patterns).

showStackerUsage() {
    echo
    echo "Usage: $0 <namespace> <stack-name> [--force]"
}

showAvailableNamespaces() {
    echo
    echo "Available namespaces:"
    local stacksRoot="${STACKS_ROOT}"
    if [[ ! -d "${stacksRoot}" ]]; then
        echo
        return
    fi
    local dir base
    for dir in "${stacksRoot}"/*/; do
        if [[ -d "${dir}" ]]; then
            base="$(basename "${dir}")"
            echo "  ${base}"
        fi
    done | sort
    echo
}

showAvailableStacksForNamespace() {
    local namespace="${1:?}"
    local nsDir="${STACKS_ROOT}/${namespace}"
    echo
    echo "Available stacks for ${namespace}:"
    local stackFile stackName
    shopt -s nullglob
    for stackFile in "${nsDir}"/*.wslb; do
        stackName="$(basename "${stackFile}" .wslb)"
        echo "  ${stackName}"
    done | sort
    shopt -u nullglob
    echo
}

showAvailableStacksForStacksDir() {
    local stacksDirLabel="${1:?}"
    local stacksAbs="${2:?}"
    echo
    echo "Available stacks for ${stacksDirLabel}:"
    local stackFile stackName
    shopt -s nullglob
    for stackFile in "${stacksAbs}"/*.wslb; do
        stackName="$(basename "${stackFile}" .wslb)"
        echo "  ${stackName}"
    done | sort
    shopt -u nullglob
    echo
}
