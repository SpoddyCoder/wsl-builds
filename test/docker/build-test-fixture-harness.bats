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

@test 'build.sh with no arguments exits nonzero and prints usage' {
	run ./build.sh
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ Available\ build\ directories: ]]
}

@test 'unknown build directory exits nonzero' {
	run ./build.sh '__EARLY_EXIT_UNKNOWN_BUILD_DIR__'
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ "Build directory '__EARLY_EXIT_UNKNOWN_BUILD_DIR__' not found" ]]
}

@test 'single-arg test-fixture lists components without running install pipeline' {
	run ./build.sh test-fixture
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ Available\ components\ for\ test-fixture: ]]
}

@test 'noop component noop-hyphen runs full harness and succeeds' {
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ test-fixture\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'comma-separated noop-hyphen (hyphen token) and noop (plain token) dispatch' {
	run ./build.sh test-fixture noop,noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ test-fixture\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'invalid component for test-fixture fails' {
	run ./build.sh test-fixture not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test '--force with noop-hyphen succeeds' {
	run ./build.sh test-fixture noop-hyphen --force
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'successful install writes ~/.wsl-build.info with OS header and component line' {
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

@test 'comma-separated installs append one record line per component' {
	run ./build.sh test-fixture noop,noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	grep -Fxq 'test-fixture v1.0.0 (noop)' "${info}"
	grep -Fxq 'test-fixture v1.0.0 (noop-hyphen)' "${info}"
	[[ "$(grep -c -F 'test-fixture v1.0.0 (noop)' "${info}")" -eq 1 ]]
	[[ "$(grep -c -F 'test-fixture v1.0.0 (noop-hyphen)' "${info}")" -eq 1 ]]
}

@test 'second install without --force skips and does not duplicate build.info lines' {
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ already\ listed ]]
	[[ "${output:?}" =~ No\ changes\ made ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c -F 'test-fixture v1.0.0 (noop-hyphen)' "${info}")" -eq 1 ]]
}

@test '--force reinstall appends another identical component line to build.info' {
	run ./build.sh test-fixture noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	run ./build.sh test-fixture noop-hyphen --force
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c -F 'test-fixture v1.0.0 (noop-hyphen)' "${info}")" -eq 2 ]]
}

@test 'touch-marker writes sentinel file and records success in build.info' {
	run ./build.sh test-fixture touch-marker
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${HOME}/.wsl-builds-test-fixture-touch-marker" ]]
	grep -Fxq 'test-fixture v1.0.0 (touch-marker)' "${HOME}/.wsl-build.info"
}

@test 'usage output lists test-fixture among available build directories' {
	run ./build.sh
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Available\ build\ directories: ]]
	[[ "${output:?}" =~ [[:space:]]test-fixture ]]
}

@test 'too many arguments exits nonzero' {
	run ./build.sh test-fixture noop-hyphen extra-junk-arg
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Too\ many\ arguments ]]
}

@test 'comma-separated valid then invalid component fails' {
	run ./build.sh test-fixture noop,not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test '--force alone without component fails validation' {
	run ./build.sh test-fixture --force
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'empty component argument fails validation' {
	run ./build.sh test-fixture ''
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'component match is case-insensitive; build.info keeps canonical token' {
	run ./build.sh test-fixture NOOP-HYPHEN
	[[ "${status:?}" -eq 0 ]]
	grep -Fxq 'test-fixture v1.0.0 (noop-hyphen)' "${HOME}/.wsl-build.info"
}

@test 'failed validation leaves ~/.wsl-build.info absent' {
	run ./build.sh '__EARLY_EXIT_UNKNOWN_BUILD_DIR__'
	[[ "${status:?}" -ne 0 ]]
	[[ ! -f "${HOME}/.wsl-build.info" ]]
	run ./build.sh test-fixture not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ ! -f "${HOME}/.wsl-build.info" ]]
}

@test 'multiple installs reuse single OS header line in build.info' {
	run ./build.sh test-fixture noop
	[[ "${status:?}" -eq 0 ]]
	run ./build.sh test-fixture touch-marker
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c '^test-fixture v[0-9]' "${info}")" -eq 2 ]]
	[[ "$(grep -cv '^test-fixture v[0-9]' "${info}")" -eq 1 ]]
}
