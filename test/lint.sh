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
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../src/common/bootstrap-common.sh
source "${SCRIPT_DIR}/../src/common/bootstrap-common.sh"
resolveRepoRootFromSourcePath "${BASH_SOURCE[0]}" ".." || exit 1
cd "$REPO_ROOT"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "shellcheck is not installed. Install it with: sudo apt-get install -y shellcheck" >&2
    exit 127
fi

if [ "$#" -gt 0 ]; then
    shellcheck --shell=bash --external-sources --source-path=SCRIPTDIR -- "$@"
else
    # wsl-builds.conf.example is omitted from this list: the file is only a template (assignments).
    # wsl-builder.sh still points ShellCheck at that example path (see # shellcheck source= in wsl-builder.sh);
    # User wsl-builds.conf paths (~/.wsl-builds.conf or WSL_BUILDS_CONF) are not linted.
    shellcheck --shell=bash --external-sources --source-path=SCRIPTDIR -- \
        wsl-builder.sh \
        configure.sh \
        test/run-tests.sh \
        test/docker/run-bats.sh \
        test/lint.sh \
        src/common/*.sh \
        src/builder/*.sh \
        src/configure/*.sh \
        src/review/*.sh \
        src/review/audit-check-helpers/*.sh \
        src/review/audit-checks/*.sh \
        builds/*/install.sh \
        builds/*/*/install.sh \
        builds/*/*/audit.sh \
        builds/*/conf.sh \
        builds/system/apt-mirror-switch \
        builds/system/change-hostname

    shopt -s nullglob
    bats_files=(
        "${REPO_ROOT}/test/docker"/*.bats
    )
    if [ "${#bats_files[@]}" -gt 0 ]; then
        shellcheck --shell=bats -- "${bats_files[@]}"
    fi

    # Syntax-only sanity check on Bash-shaped scripts (.bats use bats syntax and are omitted here).
    shopt -s globstar
    for _lint_bash_file in \
        "${REPO_ROOT}/wsl-builder.sh" \
        "${REPO_ROOT}/configure.sh" \
        "${REPO_ROOT}/test/run-tests.sh" \
        "${REPO_ROOT}/test/docker/run-bats.sh" \
        "${REPO_ROOT}/test/lint.sh" \
        "${REPO_ROOT}"/src/common/*.sh \
        "${REPO_ROOT}"/src/builder/*.sh \
        "${REPO_ROOT}"/src/configure/*.sh \
        "${REPO_ROOT}"/src/review/**/*.sh \
        "${REPO_ROOT}"/builds/*/install.sh \
        "${REPO_ROOT}"/builds/*/*/install.sh \
        "${REPO_ROOT}"/builds/*/*/audit.sh \
        "${REPO_ROOT}"/builds/*/conf.sh \
        "${REPO_ROOT}/builds/system/apt-mirror-switch" \
        "${REPO_ROOT}/builds/system/change-hostname"; do
        [[ -f "${_lint_bash_file:-}" ]] || continue
        bash -n -- "${_lint_bash_file}" || exit "${?}"
    done
    unset -v _lint_bash_file
    shopt -u globstar
    shopt -u nullglob
fi
