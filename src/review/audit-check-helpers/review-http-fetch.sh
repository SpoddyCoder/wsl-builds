#!/usr/bin/env bash
# shellcheck shell=bash
# Timed HTTP GET with small retry budget for transient failures (spec: Network and flake policy v1).

# Args: url [max_time_seconds]
# On success: response body on stdout, exit 0.
# On failure: stderr message, exit 1 (after retries exhausted for transient errors).
reviewHttpGetWithRetry() {
    local fetch_url="${1:?url required}"
    local fetch_max_time="${2:-30}"
    local attempts=3
    local delay=1
    local n=0
    local tmp
    tmp=$(mktemp) || return 1

    while [ "${n}" -lt "${attempts}" ]; do
        n=$((n + 1))
        local code
        code=$(curl -sS -L --max-time "${fetch_max_time}" -o "${tmp}" -w '%{http_code}' "${fetch_url}" || printf '%s' "000")
        if [ "${code}" -ge 200 ] && [ "${code}" -lt 300 ]; then
            cat "${tmp}"
            rm -f "${tmp}"
            return 0
        fi
        if [ "${code}" -ge 500 ] || [ "${code}" = "000" ]; then
            if [ "${n}" -lt "${attempts}" ]; then
                sleep "${delay}"
                delay=$((delay + 1))
                continue
            fi
        fi
        printf '%s\n' "reviewHttpGetWithRetry: HTTP ${code} for ${fetch_url} (attempt ${n}/${attempts})" >&2
        rm -f "${tmp}"
        return 1
    done
    printf '%s\n' "reviewHttpGetWithRetry: failed ${fetch_url}" >&2
    rm -f "${tmp}"
    return 1
}
