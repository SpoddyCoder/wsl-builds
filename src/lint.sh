#!/usr/bin/env bash
# Run ShellCheck across the repo's Bash scripts.
# Usage:
#   ./src/lint.sh                # lint the standard glob
#   ./src/lint.sh path/to/file.sh [more.sh ...]   # lint specific files
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "shellcheck is not installed. Install it with: sudo apt-get install -y shellcheck" >&2
    exit 127
fi

if [ "$#" -gt 0 ]; then
    shellcheck --shell=bash -- "$@"
else
    # shellcheck disable=SC2046
    shellcheck --shell=bash -- \
        build.sh \
        src/*.sh \
        */install*.sh \
        */conf.sh
fi
