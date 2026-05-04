#!/usr/bin/env bash
# Run ShellCheck across the repo's Bash scripts and bats tests; optional bash -n sweep.
# Usage:
#   ./test/lint.sh                # lint the standard glob
#   ./test/lint.sh path/to/file.sh [more.sh ...]   # lint specific files
#
# Flags passed to shellcheck:
#   --external-sources   follow `source` to files outside the input set, so
#                        single-file lints behave the same as the full glob
#   --source-path=SCRIPTDIR  resolve `# shellcheck source=...` directive paths
#                            relative to the directory of the script being
#                            linted (independent of the caller's CWD)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "shellcheck is not installed. Install it with: sudo apt-get install -y shellcheck" >&2
    exit 127
fi

if [ "$#" -gt 0 ]; then
    shellcheck --shell=bash --external-sources --source-path=SCRIPTDIR -- "$@"
else
    # wsl-builds.conf.example is omitted from this list: the file is only a template (assignments).
    # build.sh still points ShellCheck at that example path (see # shellcheck source= in build.sh);
    # The real config file wsl-builds.conf is gitignored and not used during lint.
    shellcheck --shell=bash --external-sources --source-path=SCRIPTDIR -- \
        build.sh \
        configure.sh \
        test/run-tests.sh \
        test/docker/run-bats.sh \
        test/lint.sh \
        src/*.sh \
        */install*.sh \
        */conf.sh \
        system/apt-mirror-switch \
        system/change-hostname

    shopt -s nullglob
    bats_files=(
        "${REPO_ROOT}/test/docker"/*.bats
    )
    if [ "${#bats_files[@]}" -gt 0 ]; then
        shellcheck --shell=bats -- "${bats_files[@]}"
    fi

    # Syntax-only sanity check on Bash-shaped scripts (.bats use bats syntax and are omitted here).
    for _lint_bash_file in \
        "${REPO_ROOT}/build.sh" \
        "${REPO_ROOT}/configure.sh" \
        "${REPO_ROOT}/test/run-tests.sh" \
        "${REPO_ROOT}/test/docker/run-bats.sh" \
        "${REPO_ROOT}/test/lint.sh" \
        "${REPO_ROOT}"/src/*.sh \
        "${REPO_ROOT}"/*/install*.sh \
        "${REPO_ROOT}"/*/conf.sh \
        "${REPO_ROOT}/system/apt-mirror-switch" \
        "${REPO_ROOT}/system/change-hostname"; do
        [[ -f "${_lint_bash_file:-}" ]] || continue
        bash -n -- "${_lint_bash_file}" || exit "${?}"
    done
    unset -v _lint_bash_file
    shopt -u nullglob
fi
