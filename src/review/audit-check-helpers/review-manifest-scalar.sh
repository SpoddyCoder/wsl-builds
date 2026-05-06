#!/usr/bin/env bash
# shellcheck shell=bash
# Minimal single-line scalar reader for maintainer manifests (audit scripts only).
# Does not parse folded blocks or complex YAML; use plain "key: value" lines at top level.

# Args: path_to_yaml key
# Prints trimmed value to stdout; empty string if missing or blank after trim.
reviewManifestScalar() {
    local file="${1:?manifest path required}"
    local key="${2:?key required}"
    local line
    line=$(grep -m1 -E "^[[:space:]]*${key}:" "${file}" 2>/dev/null || true)
    if [ -z "${line}" ]; then
        printf '%s' ''
        return 0
    fi
    local v="${line#*:}"
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    if [ "${#v}" -ge 2 ] && [ "${v:0:1}" = '"' ] && [ "${v: -1}" = '"' ]; then
        v="${v:1:-1}"
    fi
    printf '%s' "${v}"
}
