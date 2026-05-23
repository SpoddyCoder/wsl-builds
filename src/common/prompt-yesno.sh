#!/usr/bin/env bash
# Interactive [Y/n] prompts; requires print.sh (printWarning).

promptYesNo() {
    local msg=$1
    local yn
    while true; do
        printf '%s' "${msg} [Y/n]: "
        read -r yn || return 1
        case "${yn}" in
            '' | y | Y | yes | YES)
                return 0
                ;;
            n | N | no | NO)
                return 1
                ;;
            *)
                printWarning "Please answer y or n."
                ;;
        esac
    done
}

# Same as promptYesNo, but empty input and EOF default to no ([y/N]).
promptYesNoDefaultNo() {
    local msg=$1
    local yn
    while true; do
        printf '%s' "${msg} [y/N]: "
        read -r yn || return 1
        case "${yn}" in
            y | Y | yes | YES)
                return 0
                ;;
            '' | n | N | no | NO)
                return 1
                ;;
            *)
                printWarning "Please answer y or n."
                ;;
        esac
    done
}

# Same as promptYesNo, but EOF on stdin is treated as yes (default Y).
promptYesNoDefaultYesOnEof() {
    local msg=$1
    local yn
    while true; do
        printf '%s' "${msg} [Y/n]: "
        read -r yn || yn=y
        case "${yn}" in
            '' | y | Y | yes | YES)
                return 0
                ;;
            n | N | no | NO)
                return 1
                ;;
            *)
                printWarning "Please answer y or n."
                ;;
        esac
    done
}
