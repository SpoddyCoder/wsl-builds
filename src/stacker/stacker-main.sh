# Stacker main: run ./wsl-builder.sh once per non-comment line in a .wslb recipe file.

normalizeRecipeBaseName() {
    local recipeName="${1:?}"
    if [[ "${recipeName}" == *.wslb ]]; then
        recipeName="${recipeName%.wslb}"
    fi
    printf '%s' "${recipeName}"
}

# True when args may use shorthand stacks/<namespace>/<recipe>.wslb under REPO_ROOT (single-segment names only).
stackerArgsEligibleForNamespaceShorthand() {
    local stacksDirArg="${1:?}"
    local recipeArg="${2:?}"
    [[ "${stacksDirArg}" != /* ]] && [[ "${stacksDirArg}" != */* ]] && [[ "${recipeArg}" != */* ]]
}

canonicalizeExistingDirectory() {
    local dir="${1:?}"
    local absPath
    if [[ "${dir}" == /* ]]; then
        absPath="${dir}"
    else
        absPath="${REPO_ROOT}/${dir}"
    fi
    if [[ ! -d "${absPath}" ]]; then
        return 1
    fi
    if command -v realpath >/dev/null 2>&1; then
        realpath "${absPath}"
        return 0
    fi
    if readlink -f "${absPath}" >/dev/null 2>&1; then
        readlink -f "${absPath}"
        return 0
    fi
    (cd "${absPath}" && pwd)
}

invokeBuilderForLine() {
    local buildDir="${1:?}"
    local components="${2:-}"
    local useForce="${3:-false}"
    if [[ "${useForce}" == true ]]; then
        "${REPO_ROOT}/wsl-builder.sh" "${buildDir}" "${components}" --force
    else
        "${REPO_ROOT}/wsl-builder.sh" "${buildDir}" "${components}"
    fi
}

stackerMain() {
    loadWslBuildsConfOrExit

    # shellcheck source=src/stacker/stacker-arg-helpers.sh
    source "${REPO_ROOT}/src/stacker/stacker-arg-helpers.sh"

    local force=false
    local positional=("$@")

    if [[ "${#positional[@]}" -ge 1 ]] && [[ "${positional[-1]}" == "--force" ]]; then
        force=true
        positional=("${positional[@]:0:$((${#positional[@]} - 1))}")
    fi

    if [[ "${#positional[@]}" -eq 0 ]]; then
        showStackerUsage
        showAvailableStackNamespaces
        exit 1
    fi

    if [[ "${#positional[@]}" -eq 1 ]]; then
        local stacksDirArg="${positional[0]}"
        if [[ -d "${REPO_ROOT}/stacks/${stacksDirArg}" ]]; then
            showStackerUsage
            showAvailableStackRecipes "${stacksDirArg}"
            exit 1
        fi
        local stacksAbs
        if stacksAbs="$(canonicalizeExistingDirectory "${stacksDirArg}")"; then
            showStackerUsage
            showAvailableStackRecipesForStacksDir "${stacksDirArg}" "${stacksAbs}"
            exit 1
        fi
        printError "Stack namespace '${stacksDirArg}' not found"
        exit 1
    fi

    if [[ "${#positional[@]}" -ne 2 ]]; then
        printError "Too many arguments provided"
        exit 1
    fi

    local stacksDirArg="${positional[0]}"
    local recipeArg="${positional[1]}"

    local recipeBase shorthandPath stacksAbs recipeFile
    recipeBase="$(normalizeRecipeBaseName "${recipeArg}")"
    recipeFile=""

    if stackerArgsEligibleForNamespaceShorthand "${stacksDirArg}" "${recipeArg}"; then
        shorthandPath="${REPO_ROOT}/stacks/${stacksDirArg}/${recipeBase}.wslb"
        if [[ -f "${shorthandPath}" ]]; then
            recipeFile="${shorthandPath}"
        fi
    fi

    if [[ -z "${recipeFile}" ]]; then
        if ! stacksAbs="$(canonicalizeExistingDirectory "${stacksDirArg}")"; then
            printError "Stacks directory not found or inaccessible: ${stacksDirArg}"
            exit 1
        fi
        recipeFile="${stacksAbs}/${recipeBase}.wslb"
    fi

    if [[ ! -f "${recipeFile}" ]]; then
        printError "Recipe not found: ${recipeFile}"
        exit 1
    fi

    local line buildDir components
    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        read -r buildDir components <<< "${line}"
        invokeBuilderForLine "${buildDir}" "${components}" "${force}"
    done <"${recipeFile}"
}
