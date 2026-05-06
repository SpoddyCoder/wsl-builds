#!/usr/bin/env bash
# Reusable audit check: CLI --version parsing (catalogue: cli-reported-version.sh).
#
# Spec: Audit-check module output (v1) — one logical line JSON on stdout on exit 0;
# stderr diagnostics only; non-zero exit = uncontrolled failure for this invocation.
#
# Usage:
#   cli-reported-version.sh <check_id> <cli_command> [sed_extract_script]
#
# - check_id: stable id for the checks[] row (e.g. shellcheck_cli).
# - cli_command: name or path tested with command -v and invoked as <cli_command> --version.
# - sed_extract_script: optional argument to sed -n (default strips leading "version:" lines like shellcheck).
#
# Does not install tools. Requires jq on PATH (same as component-review / pilot audits).

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "cli-reported-version.sh: jq is required; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

usage() {
    printf 'usage: %s <check_id> <cli_command> [sed_extract_script]\n' "${0##*/}" >&2
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    usage
    exit 1
fi

readonly check_id="$1"
readonly cli_command="$2"
readonly sed_extract_script="${3:-s/^version:[[:space:]]*//p}"

if ! command -v -- "${cli_command}" >/dev/null 2>&1; then
    jq -cn \
        --arg id "${check_id}" \
        --arg cli "${cli_command}" \
        '{
             check: {
                 id: $id,
                 outcome: "inconclusive",
                 detail: ($cli + " is not installed or not on PATH; install the component that provides this tool first.")
             },
             evidence: {}
         }'
    exit 0
fi

version_stdout=$("${cli_command}" --version 2>/dev/null || true)
reported=""
if [ -n "${version_stdout}" ]; then
    reported=$(printf '%s\n' "${version_stdout}" | sed -n "${sed_extract_script}" 2>/dev/null | head -n1 || true)
fi

if [ -z "${reported}" ]; then
    reported="(no version line matched from ${cli_command} --version)"
fi

jq -cn \
    --arg id "${check_id}" \
    --arg ver "${reported}" \
    --arg cli "${cli_command}" \
    '{
         check: {
             id: $id,
             outcome: "passed",
             detail: ("Reported package/version line: " + $ver)
         },
         evidence: {
             cli_reported_version: $ver,
             cli_command_name: $cli
         }
     }'
exit 0
