#!/usr/bin/env bash
# Stacker arg and listing helpers (mirrors src/builder/arg-helpers.sh patterns).

showStackerUsage() {
    echo
    echo "Usage: $0 <namespace> <recipe-name> [--force]"
}

showAvailableStackNamespaces() {
    echo
    echo "Available stack namespaces:"
    local stacksRoot="${REPO_ROOT}/stacks"
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

showAvailableStackRecipes() {
    local namespace="${1:?}"
    local nsDir="${REPO_ROOT}/stacks/${namespace}"
    echo
    echo "Available recipes for ${namespace}:"
    local recipeFile recipeName
    shopt -s nullglob
    for recipeFile in "${nsDir}"/*.wslb; do
        recipeName="$(basename "${recipeFile}" .wslb)"
        echo "  ${recipeName}"
    done | sort
    shopt -u nullglob
    echo
}

showAvailableStackRecipesForStacksDir() {
    local stacksDirLabel="${1:?}"
    local stacksAbs="${2:?}"
    echo
    echo "Available recipes for ${stacksDirLabel}:"
    local recipeFile recipeName
    shopt -s nullglob
    for recipeFile in "${stacksAbs}"/*.wslb; do
        recipeName="$(basename "${recipeFile}" .wslb)"
        echo "  ${recipeName}"
    done | sort
    shopt -u nullglob
    echo
}
