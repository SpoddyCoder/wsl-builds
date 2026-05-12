# Stacker main: run ./wsl-builder.sh once per non-comment line in a stacks/<namespace>/<stack>.wslb file.

normalizeStackBaseName() {
    local stackName="${1:?}"
    if [[ "${stackName}" == *.wslb ]]; then
        stackName="${stackName%.wslb}"
    fi
    printf '%s' "${stackName}"
}

# True when args may use shorthand stacks/<namespace>/<stack>.wslb under REPO_ROOT (single-segment names only).
stackerArgsEligibleForNamespaceShorthand() {
    local namespaceArg="${1:?}"
    local stackArg="${2:?}"
    [[ "${namespaceArg}" != /* ]] && [[ "${namespaceArg}" != */* ]] && [[ "${stackArg}" != */* ]]
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

    # shellcheck source=src/stacker/stacks-root.sh
    source "${REPO_ROOT}/src/stacker/stacks-root.sh"
    resolveStacksRootFromRepoRoot "${REPO_ROOT}" || exit 1

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
        showAvailableNamespaces
        exit 1
    fi

    if [[ "${#positional[@]}" -eq 1 ]]; then
        local firstArg="${positional[0]}"
        if [[ -d "${STACKS_ROOT}/${firstArg}" ]]; then
            showStackerUsage
            showAvailableStacksForNamespace "${firstArg}"
            exit 1
        fi
        local stacksAbs
        if stacksAbs="$(canonicalizeExistingDirectory "${firstArg}")"; then
            showStackerUsage
            showAvailableStacksForStacksDir "${firstArg}" "${stacksAbs}"
            exit 1
        fi
        if stackerArgsEligibleForNamespaceShorthand "${firstArg}" "_"; then
            printError "Namespace '${firstArg}' not found"
        else
            printError "Stacks directory not found or inaccessible: ${firstArg}"
        fi
        exit 1
    fi

    if [[ "${#positional[@]}" -ne 2 ]]; then
        printError "Too many arguments provided"
        exit 1
    fi

    local firstArg="${positional[0]}"
    local stackArg="${positional[1]}"

    local stackBase shorthandPath stacksAbs stackFile
    stackBase="$(normalizeStackBaseName "${stackArg}")"
    stackFile=""

    if stackerArgsEligibleForNamespaceShorthand "${firstArg}" "${stackArg}"; then
        shorthandPath="${STACKS_ROOT}/${firstArg}/${stackBase}.wslb"
        if [[ -f "${shorthandPath}" ]]; then
            stackFile="${shorthandPath}"
        fi
    fi

    if [[ -z "${stackFile}" ]]; then
        if ! stacksAbs="$(canonicalizeExistingDirectory "${firstArg}")"; then
            printError "Stacks directory not found or inaccessible: ${firstArg}"
            exit 1
        fi
        stackFile="${stacksAbs}/${stackBase}.wslb"
    fi

    if [[ ! -f "${stackFile}" ]]; then
        printError "Stack not found: ${stackFile}"
        exit 1
    fi

    local stackLines=()
    mapfile -t stackLines <"${stackFile}"

    local line buildDir components
    for line in "${stackLines[@]}"; do
        [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        read -r buildDir components <<< "${line}"
        invokeBuilderForLine "${buildDir}" "${components}" "${force}"
    done
}
