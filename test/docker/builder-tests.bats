#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only ./build.sh regressions (test-fixture harness).

setup() {
	TEST_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
	TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
	_BATS_FAKE_HOME="$(mktemp -d)"
	export HOME="$_BATS_FAKE_HOME"
	cd "$TEST_ROOT" || return 1
	/bin/cp -f "${TEST_DIR}/wsl-builds.conf" "${TEST_ROOT}/wsl-builds.conf"
}

teardown() {
	rm -rf "${_BATS_FAKE_HOME:-}"
}

@test 'B1: build.sh with no arguments exits nonzero and prints usage' {
	run ./build.sh
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ Available\ build\ directories: ]]
}

@test 'B2: unknown build directory exits nonzero' {
	run ./build.sh '__EARLY_EXIT_UNKNOWN_BUILD_DIR__'
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ "Build directory '__EARLY_EXIT_UNKNOWN_BUILD_DIR__' not found" ]]
}

@test 'B3: single-arg test-fixture lists components without running install pipeline' {
	run ./build.sh test-fixture
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ Available\ components\ for\ test-fixture: ]]
}

@test 'B4: noop component noop-hyphen runs full harness and succeeds' {
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ test-fixture\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'B5: comma-separated noop-hyphen (hyphen token) and noop (plain token) dispatch' {
	run ./build.sh test-fixture noop,noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ test-fixture\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'B6: invalid component for test-fixture fails' {
	run ./build.sh test-fixture not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'B7: --force with noop-hyphen succeeds' {
	run ./build.sh test-fixture noop-hyphen --force
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'B8: successful install writes ~/.wsl-build.info with OS header and component line' {
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	[[ -f "${info:?}" ]]
	local lines
	lines="$(wc -l < "${info}")"
	[[ "${lines// /}" -ge 2 ]]
	grep -Fxq 'test-fixture v1.0.0 (noop-hyphen)' "${info}"
	[[ "$(head -n1 "${info}")" =~ [[:space:]] ]]
}

@test 'B9: comma-separated installs append one record line per component' {
	run ./build.sh test-fixture noop,noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	grep -Fxq 'test-fixture v1.0.0 (noop)' "${info}"
	grep -Fxq 'test-fixture v1.0.0 (noop-hyphen)' "${info}"
	[[ "$(grep -c -F 'test-fixture v1.0.0 (noop)' "${info}")" -eq 1 ]]
	[[ "$(grep -c -F 'test-fixture v1.0.0 (noop-hyphen)' "${info}")" -eq 1 ]]
}

@test 'B10: second install without --force skips and does not duplicate build.info lines' {
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ already\ listed ]]
	[[ "${output:?}" =~ No\ changes\ made ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c -F 'test-fixture v1.0.0 (noop-hyphen)' "${info}")" -eq 1 ]]
}

@test 'B11: --force reinstall appends another identical component line to build.info' {
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	run ./build.sh test-fixture noop-hyphen --force
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c -F 'test-fixture v1.0.0 (noop-hyphen)' "${info}")" -eq 2 ]]
}

@test 'B12: touch-marker writes sentinel file and records success in build.info' {
	run ./build.sh test-fixture touch-marker
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${HOME}/.wsl-builds-test-fixture-touch-marker" ]]
	grep -Fxq 'test-fixture v1.0.0 (touch-marker)' "${HOME}/.wsl-build.info"
}

@test 'B13: usage output lists test-fixture among available build directories' {
	run ./build.sh
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Available\ build\ directories: ]]
	[[ "${output:?}" =~ [[:space:]]test-fixture ]]
}

@test 'B14: too many arguments exits nonzero' {
	run ./build.sh test-fixture noop-hyphen extra-junk-arg
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Too\ many\ arguments ]]
}

@test 'B15: comma-separated valid then invalid component fails' {
	run ./build.sh test-fixture noop,not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'B16: --force alone without component fails validation' {
	run ./build.sh test-fixture --force
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'B17: empty component argument fails validation' {
	run ./build.sh test-fixture ''
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'B18: component match is case-insensitive; build.info keeps canonical token' {
	run ./build.sh test-fixture NOOP-HYPHEN
	[[ "${status:?}" -eq 0 ]]
	grep -Fxq 'test-fixture v1.0.0 (noop-hyphen)' "${HOME}/.wsl-build.info"
}

@test 'B19: failed validation leaves ~/.wsl-build.info absent' {
	run ./build.sh '__EARLY_EXIT_UNKNOWN_BUILD_DIR__'
	[[ "${status:?}" -ne 0 ]]
	[[ ! -f "${HOME}/.wsl-build.info" ]]
	run ./build.sh test-fixture not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ ! -f "${HOME}/.wsl-build.info" ]]
}

@test 'B20: multiple installs reuse single OS header line in build.info' {
	run ./build.sh test-fixture noop
	[[ "${status:?}" -eq 0 ]]
	run ./build.sh test-fixture touch-marker
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c '^test-fixture v[0-9]' "${info}")" -eq 2 ]]
	[[ "$(grep -cv '^test-fixture v[0-9]' "${info}")" -eq 1 ]]
}

@test 'B21: WSL_BUILDS_CONF set to readable file is sourced and path is printed' {
	local alt_conf="${BATS_TEST_TMPDIR}/alt-wsl-builds.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" == *"Using: ${alt_conf}"* ]]
}

@test 'B22: WSL_BUILDS_CONF set but not readable exits nonzero' {
	WSL_BUILDS_CONF="${BATS_TEST_TMPDIR}/wsl-builds-does-not-exist.conf" run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" == *'WSL_BUILDS_CONF is set but not readable:'* ]]
}

@test 'B23: getfile-harness exercises getFile cache hit download cleanupGetFiles and records success' {
	run ./build.sh test-fixture getfile-harness
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Using\ locally\ cached\ version ]]
	[[ "${output:?}" =~ Downloading\ and\ caching ]]
	grep -Fxq 'test-fixture v1.0.0 (getfile-harness)' "${HOME}/.wsl-build.info"
}

@test 'B24: file-edit-harness updates shell rc and /etc/wsl.conf' {
	_BATS_WSL_CONF_BAK="${BATS_TEST_TMPDIR}/wsl.conf.prior"
	_BATS_WSL_CONF_EXISTS_prior=0
	if [[ -f /etc/wsl.conf ]]; then
		_BATS_WSL_CONF_EXISTS_prior=1
		cp -- /etc/wsl.conf "${_BATS_WSL_CONF_BAK}"
	fi
	_batsRestoreWslConf() {
		if [[ "${_BATS_WSL_CONF_EXISTS_prior}" -eq 1 ]]; then
			cp -- "${_BATS_WSL_CONF_BAK}" /etc/wsl.conf
		else
			rm -f /etc/wsl.conf
		fi
	}
	trap '_batsRestoreWslConf' EXIT

	cat >/etc/wsl.conf <<'EOF'
[network]
# harness dummy seed
EOF

	run ./build.sh test-fixture file-edit-harness
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ test-fixture\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
	grep -qF '[wsl-builds-test]' /etc/wsl.conf
	grep -qF 'fixture = true' /etc/wsl.conf
	grep -qF '# harness dummy seed' /etc/wsl.conf
	grep -qF '# >>> wsl-builds:test-fixture-file-harness >>>' "${HOME}/.bashrc"
	grep -qF 'export WSL_BUILDS_TEST_FIXTURE_HARNESS=1' "${HOME}/.bashrc"
	grep -qF '# <<< wsl-builds:test-fixture-file-harness <<<' "${HOME}/.bashrc"
	grep -Fxq 'test-fixture v1.0.0 (file-edit-harness)' "${HOME}/.wsl-build.info"
}

@test 'B25: getfile-stale-harness stale cache default yes keeps seeded payload' {
	run bash -c 'export WSL_BUILDS_GETFILE_STALE_EXPECT=cache; printf "\n" | ./build.sh test-fixture getfile-stale-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Cached\ wsl-builds-fixture-stale-cache\.txt\ is\ about\ [0-9]+\ days\ old\ \(stale\ after\ [0-9]+\ days\) ]]
	[[ "${output:?}" =~ Use\ cached\ file\ anyway\? ]]
	[[ "${output:?}" =~ Using\ locally\ cached\ version ]]
	grep -Fxq 'test-fixture v1.0.0 (getfile-stale-harness)' "${HOME}/.wsl-build.info"
}

@test 'B26: getfile-stale-harness stale cache n refreshes from fixture URL' {
	run bash -c 'export WSL_BUILDS_GETFILE_STALE_EXPECT=refresh; printf "n\n" | ./build.sh test-fixture getfile-stale-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Cached\ wsl-builds-fixture-stale-cache\.txt\ is\ about\ [0-9]+\ days\ old\ \(stale\ after\ [0-9]+\ days\) ]]
	[[ "${output:?}" =~ Downloading\ fresh\ copy ]]
	grep -Fxq 'test-fixture v1.0.0 (getfile-stale-harness)' "${HOME}/.wsl-build.info"
}
