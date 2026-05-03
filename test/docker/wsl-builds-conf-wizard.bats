#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only regressions for ./configure.sh (wizard).
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
	run ./configure.sh --help
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Usage: ]]
}

@test 'W2: unknown option fails' {
	run ./configure.sh --not-a-real-flag
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Unknown\ option ]]
}

@test 'W3: --noninteractive creates repo wsl-builds.conf from example when missing' {
	rm -f "${TEST_ROOT}/wsl-builds.conf"
	run ./configure.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${TEST_ROOT}/wsl-builds.conf" ]]
	[[ "${output:?}" =~ Created ]]
	[[ "${output:?}" =~ example ]]
}

@test 'W4: --noninteractive when repo conf already exists is no-op' {
	[[ -f "${TEST_ROOT}/wsl-builds.conf" ]]
	local sum_before
	sum_before="$(sha256sum "${TEST_ROOT}/wsl-builds.conf")"
	run ./configure.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ already\ exists ]]
	[[ "${sum_before}" == "$(sha256sum "${TEST_ROOT}/wsl-builds.conf")" ]]
}

@test 'W5: non-TTY stdin auto-forces noninteractive (copy when missing)' {
	rm -f "${TEST_ROOT}/wsl-builds.conf"
	run ./configure.sh </dev/null
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${TEST_ROOT}/wsl-builds.conf" ]]
	[[ "${output:?}" =~ Created ]]
}

@test 'W6: --defaults alias matches --noninteractive' {
	rm -f "${TEST_ROOT}/wsl-builds.conf"
	run ./configure.sh --defaults
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${TEST_ROOT}/wsl-builds.conf" ]]
	[[ "${output:?}" =~ Created ]]
}

@test 'W7: no managed shell rc block after noninteractive when host default unavailable' {
	rm -f "${TEST_ROOT}/wsl-builds.conf"
	run ./configure.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	if [[ -f "${HOME}/.bashrc" ]]; then
		! grep -qF 'wsl-builds (managed)' "${HOME}/.bashrc"
		! grep -qF 'wsl-builds:wsl-builds-conf' "${HOME}/.bashrc"
	fi
	if [[ -f "${HOME}/.zshrc" ]]; then
		! grep -qF 'wsl-builds (managed)' "${HOME}/.zshrc"
		! grep -qF 'wsl-builds:wsl-builds-conf' "${HOME}/.zshrc"
	fi
}

@test 'W8: removeManagedShellRcRegion with no ~/.bashrc is no-op' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
	removeManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}"
	[[ ! -f "${HOME}/.bashrc" ]]
}

@test 'W9: removeManagedShellRcRegion strips only named region' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
	local begin end
	begin='# >>> wsl-builds:wsl-builds-conf >>>'
	end='# <<< wsl-builds:wsl-builds-conf <<<'
	cat >"${HOME}/.bashrc" <<EOF
before
${begin}
inside line
${end}
after
EOF
	removeManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}"
	run grep -c . "${HOME}/.bashrc"
	[[ "${output:?}" == 2 ]]
	grep -qx 'before' "${HOME}/.bashrc"
	grep -qx 'after' "${HOME}/.bashrc"
	run grep -q inside "${HOME}/.bashrc"
	[[ "${status:?}" -ne 0 ]]
}

@test 'W10: removeManagedShellRcRegion with file but no markers leaves file unchanged' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
	echo 'user-only' >"${HOME}/.bashrc"
	local sum_before
	sum_before="$(sha256sum "${HOME}/.bashrc")"
	removeManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}"
	[[ "${sum_before}" == "$(sha256sum "${HOME}/.bashrc")" ]]
}

@test 'W11: replaceManagedShellRcRegion is idempotent; final path wins' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
	echo 'outside' >"${HOME}/.bashrc"
	local body
	body="$(printf 'export WSL_BUILDS_CONF=%q\n' '/first/path')"
	replaceManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}" "${body}"
	body="$(printf 'export WSL_BUILDS_CONF=%q\n' '/second/path')"
	replaceManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}" "${body}"
	[[ "$(grep -cF '# >>> wsl-builds:wsl-builds-conf >>>' "${HOME}/.bashrc")" -eq 1 ]]
	grep -qE '^export WSL_BUILDS_CONF=.*second/path' "${HOME}/.bashrc"
	grep -qx 'outside' "${HOME}/.bashrc"
}

@test 'W12: replaceManagedShellRcRegion quotes path with spaces and $' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
	local weird body
	weird=$'/tmp/weird dir/with $ymbol'
	body="$(printf 'export WSL_BUILDS_CONF=%q\n' "${weird}")"
	replaceManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}" "${body}"
	run grep '^export WSL_BUILDS_CONF=' "${HOME}/.bashrc"
	# shellcheck disable=SC1090,SC1091
	source "${HOME}/.bashrc"
	[[ "${WSL_BUILDS_CONF:?}" == "${weird}" ]]
}

@test 'W13: normalizeHostConfPath absolute readable path returns same path' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
	local f out
	f="$(mktemp)"
	out="$(normalizeHostConfPath "${f}")"
	[[ "${out}" == "${f}" ]]
	rm -f "${f}"
}

@test 'W14: normalizeHostConfPath empty input fails' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
	if normalizeHostConfPath ""; then
		return 1
	fi
}

@test 'W15: normalizeHostConfPath non-absolute path fails without wslpath success' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
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
	run ./configure.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	run grep -qF 'wsl-builds (managed)' "${HOME}/.bashrc"
	[[ "${status:?}" -ne 0 ]]
	run grep -qF 'wsl-builds:wsl-builds-conf' "${HOME}/.bashrc"
	[[ "${status:?}" -ne 0 ]]
	grep -qx 'before' "${HOME}/.bashrc"
	grep -qx 'after' "${HOME}/.bashrc"
}

@test 'W19: replaceManagedShellRcRegion updates bashrc and zshrc when both exist' {
	# shellcheck disable=SC1091
	source "${TEST_ROOT}/configure.sh"
	echo 'b' >"${HOME}/.bashrc"
	echo 'z' >"${HOME}/.zshrc"
	local body
	body="$(printf 'export WSL_BUILDS_CONF=%q\n' '/host/conf')"
	replaceManagedShellRcRegion "${SHELL_RC_WIZARD_REGION_ID}" "${body}"
	[[ "$(grep -cF '# >>> wsl-builds:wsl-builds-conf >>>' "${HOME}/.bashrc")" -eq 1 ]]
	[[ "$(grep -cF '# >>> wsl-builds:wsl-builds-conf >>>' "${HOME}/.zshrc")" -eq 1 ]]
	grep -qE '^export WSL_BUILDS_CONF=.*/host/conf' "${HOME}/.bashrc"
	grep -qE '^export WSL_BUILDS_CONF=.*/host/conf' "${HOME}/.zshrc"
	grep -qx 'b' "${HOME}/.bashrc"
	grep -qx 'z' "${HOME}/.zshrc"
}

@test 'W17: shell hint warns when WSL_BUILDS_CONF is still set in env' {
	WSL_BUILDS_CONF=/tmp/leftover-host-path run ./configure.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ WSL_BUILDS_CONF\ still\ set ]]
}

@test 'W18: shell hint silent when WSL_BUILDS_CONF is unset' {
	run ./configure.sh --noninteractive
	[[ "${status:?}" -eq 0 ]]
	[[ ! "${output:?}" =~ WSL_BUILDS_CONF\ still\ set ]]
}
