#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only ./wsl-stacker.sh regressions (fixture-builder harness).

setup() {
	TEST_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
	TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
	_BATS_FAKE_HOME="$(mktemp -d)"
	export HOME="$_BATS_FAKE_HOME"
	cd "$TEST_ROOT" || return 1
	/bin/cp -f "${TEST_DIR}/wsl-builds.conf" "${HOME}/.wsl-builds.conf"
	_STACKER_TMP="$(mktemp -d)"
}

teardown() {
	rm -rf "${_BATS_FAKE_HOME:-}"
	rm -rf "${_STACKER_TMP:-}"
}

@test 'S1: wsl-stacker.sh with no arguments exits nonzero and prints usage' {
	run ./wsl-stacker.sh
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ ! "${output:?}" =~ Invalid\ arguments ]]
	[[ "${output:?}" =~ Available\ stack\ namespaces: ]]
}

@test 'S1b: namespace-only invocation lists recipes like builder component listing' {
	local ns="bats_stacker_ns_list_${RANDOM}"
	mkdir -p "${TEST_ROOT}/stacks/${ns}"
	echo 'fixture-builder noop' >"${TEST_ROOT}/stacks/${ns}/alpha.wslb"
	echo 'fixture-builder noop' >"${TEST_ROOT}/stacks/${ns}/beta.wslb"
	run ./wsl-stacker.sh "${ns}"
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ Available\ recipes\ for\ ${ns}: ]]
	[[ "${output:?}" =~ alpha ]]
	[[ "${output:?}" =~ beta ]]
	rm -rf "${TEST_ROOT}/stacks/${ns}"
}

@test 'S2: missing recipe file exits nonzero' {
	mkdir -p "${_STACKER_TMP}/empty-stacks"
	run ./wsl-stacker.sh "${_STACKER_TMP}/empty-stacks" no-such-recipe
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Recipe\ not\ found: ]]
}

@test 'S3: minimal recipe fixture-builder noop succeeds' {
	mkdir -p "${_STACKER_TMP}/st/a"
	echo 'fixture-builder noop' >"${_STACKER_TMP}/st/a/b.wslb"
	run ./wsl-stacker.sh "${_STACKER_TMP}/st" a/b
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
}

@test 'S4: recipe may be passed with redundant .wslb suffix' {
	mkdir -p "${_STACKER_TMP}/st2/a"
	echo 'fixture-builder noop' >"${_STACKER_TMP}/st2/a/b.wslb"
	run ./wsl-stacker.sh "${_STACKER_TMP}/st2" a/b.wslb
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
}

@test 'S5: shorthand namespace recipe resolves to stacks/<namespace>/<recipe>.wslb' {
	local ns="bats_stacker_ns_${RANDOM}"
	mkdir -p "${TEST_ROOT}/stacks/${ns}"
	echo 'fixture-builder noop' >"${TEST_ROOT}/stacks/${ns}/minimal.wslb"
	run ./wsl-stacker.sh "${ns}" minimal
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
	rm -rf "${TEST_ROOT}/stacks/${ns}"
}

@test 'S6: long form when shorthand file missing (stacks-dir stacks, flat recipe name)' {
	local flat="bats_stacker_flat_${RANDOM}"
	echo 'fixture-builder noop' >"${TEST_ROOT}/stacks/${flat}.wslb"
	run ./wsl-stacker.sh stacks "${flat}"
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
	rm -f "${TEST_ROOT}/stacks/${flat}.wslb"
}
