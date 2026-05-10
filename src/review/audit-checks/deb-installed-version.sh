#!/usr/bin/env bash
# Reusable audit check: Debian package version from dpkg (catalogue: deb-installed-version.sh).
#
# Spec: Audit-check module output (v1).
# Usage: deb-installed-version.sh <check_id> <deb_package_name>

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "deb-installed-version.sh: jq is required; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

usage() {
    printf 'usage: %s <check_id> <deb_package_name>\n' "${0##*/}" >&2
}

if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

readonly check_id="$1"
readonly deb_package="$2"

if [ -z "${deb_package}" ]; then
    printf '%s\n' 'deb-installed-version.sh: package name must be non-empty' >&2
    exit 1
fi

if ! command -v dpkg-query >/dev/null 2>&1; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg pkg "${deb_package}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "inconclusive",
             detail: "dpkg-query is not available; not a Debian/apt environment."
         }'
    exit 0
fi

if ! dpkg-query -W -f='${Status}\n' "${deb_package}" 2>/dev/null | grep -q 'install ok installed'; then
    jq -cn \
        --arg audit_check_id "${check_id}" \
        --arg pkg "${deb_package}" \
        '{
             audit_check_id: $audit_check_id,
             outcome: "inconclusive",
             detail: ("Debian package \"" + $pkg + "\" is not installed (dpkg)."),
             evidence: { deb_package: $pkg }
         }'
    exit 0
fi

deb_ver=$(dpkg-query -W -f='${Version}\n' "${deb_package}" 2>/dev/null | head -n1 || true)
if [ -z "${deb_ver}" ]; then
    deb_ver="(empty version from dpkg-query)"
fi

jq -cn \
    --arg audit_check_id "${check_id}" \
    --arg pkg "${deb_package}" \
    --arg ver "${deb_ver}" \
    '{
         audit_check_id: $audit_check_id,
         outcome: "passed",
         detail: ("Installed Debian package version: " + $ver),
         evidence: {
             deb_package: $pkg,
             deb_installed_version: $ver
         }
     }'
exit 0
