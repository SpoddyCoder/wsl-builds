# Harness-only component (automated testing): reports one stdin line for stacker regressions.
# shellcheck shell=bash

printInfo "Installing stdin-probe"

stdin_probe_line="<eof>"
read -r stdin_probe_line || true
if [[ -z "${stdin_probe_line}" ]]; then
    stdin_probe_line="<eof>"
fi
printInfo "stdin-probe stdin: ${stdin_probe_line}"

printInfo "stdin-probe installed"
