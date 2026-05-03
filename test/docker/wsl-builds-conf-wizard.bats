#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only regressions for ./wsl-builds-conf.sh (wizard).
# Snapshots repo-root wsl-builds.conf each test and restores in teardown so
# build-test-fixture-harness.bats (same image run) keeps a valid harness file.

setup() {
	TEST_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
	WIZARD_FAKE_HOME="$(mktemp -d)"
	export HOME="${WIZARD_FAKE_HOME}"
	unset WSL_BUILDS_CONF
	cd "${TEST_ROOT}" || return 1
	WIZARD_CONF_SNAPSHOT="$(mktemp)"
	if [[ -f "${TEST_ROOT}/wsl-builds.conf" ]]; then
		cp -f "${TEST_ROOT}/wsl-builds.conf" "${WIZARD_CONF_SNAPSHOT}"
	else
		rm -f "${WIZARD_CONF_SNAPSHOT}"
		WIZARD_CONF_SNAPSHOT=""
	fi
}

teardown() {
	if [[ -n "${WIZARD_CONF_SNAPSHOT:-}" ]] && [[ -f "${WIZARD_CONF_SNAPSHOT}" ]]; then
		cp -f "${WIZARD_CONF_SNAPSHOT}" "${TEST_ROOT}/wsl-builds.conf"
		rm -f "${WIZARD_CONF_SNAPSHOT}"
	fi
	rm -rf "${WIZARD_FAKE_HOME:-}"
}

@test 'W1: --help exits 0 and prints usage' {
	run ./wsl-builds-conf.sh --help
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Usage: ]]
}

@test 'W2: unknown option fails' {
	run ./wsl-builds-conf.sh --not-a-real-flag
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Unknown\ option ]]
}

@test 'W3: --noninteractive creates repo wsl-builds.conf from example when missing' {
	rm -f "${TEST_ROOT}/wsl-builds.conf"
	run ./wsl-builds-conf.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${TEST_ROOT}/wsl-builds.conf" ]]
	[[ "${output:?}" =~ Created ]]
	[[ "${output:?}" =~ example ]]
}

@test 'W4: --noninteractive when repo conf already exists is no-op' {
	[[ -f "${TEST_ROOT}/wsl-builds.conf" ]]
	local sum_before
	sum_before="$(sha256sum "${TEST_ROOT}/wsl-builds.conf")"
	run ./wsl-builds-conf.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ already\ exists ]]
	[[ "${sum_before}" == "$(sha256sum "${TEST_ROOT}/wsl-builds.conf")" ]]
}

@test 'W5: non-TTY stdin auto-forces noninteractive (copy when missing)' {
	rm -f "${TEST_ROOT}/wsl-builds.conf"
	run ./wsl-builds-conf.sh </dev/null
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${TEST_ROOT}/wsl-builds.conf" ]]
	[[ "${output:?}" =~ Created ]]
}

@test 'W6: --defaults alias matches --noninteractive' {
	rm -f "${TEST_ROOT}/wsl-builds.conf"
	run ./wsl-builds-conf.sh --defaults
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${TEST_ROOT}/wsl-builds.conf" ]]
	[[ "${output:?}" =~ Created ]]
}

@test 'W7: no managed ~/.bashrc block after noninteractive when host default unavailable' {
	rm -f "${TEST_ROOT}/wsl-builds.conf"
	run ./wsl-builds-conf.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	if [[ -f "${HOME}/.bashrc" ]]; then
		! grep -qF 'wsl-builds (managed)' "${HOME}/.bashrc"
	fi
}

@test 'W8: removeManagedBashrcBlock with no ~/.bashrc is no-op' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/wsl-builds-conf.sh"
	removeManagedBashrcBlock
	[[ ! -f "${HOME}/.bashrc" ]]
}

@test 'W9: removeManagedBashrcBlock strips only managed region' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/wsl-builds-conf.sh"
	cat >"${HOME}/.bashrc" <<EOF
before
${MANAGED_BEGIN}
inside line
${MANAGED_END}
after
EOF
	removeManagedBashrcBlock
	run grep -c . "${HOME}/.bashrc"
	[[ "${output:?}" == 2 ]]
	grep -qx 'before' "${HOME}/.bashrc"
	grep -qx 'after' "${HOME}/.bashrc"
	run grep -q inside "${HOME}/.bashrc"
	[[ "${status:?}" -ne 0 ]]
}

@test 'W10: removeManagedBashrcBlock with file but no markers leaves file unchanged' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/wsl-builds-conf.sh"
	echo 'user-only' >"${HOME}/.bashrc"
	local sum_before
	sum_before="$(sha256sum "${HOME}/.bashrc")"
	removeManagedBashrcBlock
	[[ "${sum_before}" == "$(sha256sum "${HOME}/.bashrc")" ]]
}

@test 'W11: writeManagedBashrcBlock replace is idempotent; final path wins' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/wsl-builds-conf.sh"
	echo 'outside' >"${HOME}/.bashrc"
	writeManagedBashrcBlock '/first/path'
	writeManagedBashrcBlock '/second/path'
	[[ "$(grep -cF "${MANAGED_BEGIN}" "${HOME}/.bashrc")" -eq 1 ]]
	grep -qE '^export WSL_BUILDS_CONF=.*second/path' "${HOME}/.bashrc"
	grep -qx 'outside' "${HOME}/.bashrc"
}

@test 'W12: writeManagedBashrcBlock quotes path with spaces and $' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/wsl-builds-conf.sh"
	local weird
	weird=$'/tmp/weird dir/with $ymbol'
	writeManagedBashrcBlock "${weird}"
	run grep '^export WSL_BUILDS_CONF=' "${HOME}/.bashrc"
	# shellcheck disable=SC1090,SC1091
	source "${HOME}/.bashrc"
	[[ "${WSL_BUILDS_CONF:?}" == "${weird}" ]]
}

@test 'W13: normalizeHostConfPath absolute readable path returns same path' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/wsl-builds-conf.sh"
	local f out
	f="$(mktemp)"
	out="$(normalizeHostConfPath "${f}")"
	[[ "${out}" == "${f}" ]]
	rm -f "${f}"
}

@test 'W14: normalizeHostConfPath empty input fails' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/wsl-builds-conf.sh"
	if normalizeHostConfPath ""; then
		return 1
	fi
}

@test 'W15: normalizeHostConfPath non-absolute path fails without wslpath success' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/wsl-builds-conf.sh"
	if normalizeHostConfPath 'relative/no/wslpath/happy'; then
		return 1
	fi
}

@test 'W16: --noninteractive strips a pre-seeded managed ~/.bashrc block' {
	cat >"${HOME}/.bashrc" <<EOF
before
# >>> wsl-builds (managed) >>>
export WSL_BUILDS_CONF=/stale/host/path
# <<< wsl-builds (managed) <<<
after
EOF
	run ./wsl-builds-conf.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	run grep -qF 'wsl-builds (managed)' "${HOME}/.bashrc"
	[[ "${status:?}" -ne 0 ]]
	grep -qx 'before' "${HOME}/.bashrc"
	grep -qx 'after' "${HOME}/.bashrc"
}

@test 'W17: shell hint warns when WSL_BUILDS_CONF is still set in env' {
	WSL_BUILDS_CONF=/tmp/leftover-host-path run ./wsl-builds-conf.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ WSL_BUILDS_CONF\ still\ set ]]
}

@test 'W18: shell hint silent when WSL_BUILDS_CONF is unset' {
	run ./wsl-builds-conf.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	[[ ! "${output:?}" =~ WSL_BUILDS_CONF\ still\ set ]]
}
