#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only ./build.sh regressions (noop test-fixture harness).

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

@test 'comma-separated noop components hyphen mapping and dispatch' {
	run ./build.sh test-fixture noop-plain,noop-hyphen
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
