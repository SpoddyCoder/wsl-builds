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
	[[ "${output:?}" =~ Available\ namespaces: ]]
}

@test 'S1b: namespace-only invocation lists stacks like builder component listing' {
	local ns="bats_stacker_ns_list_${RANDOM}"
	mkdir -p "${TEST_ROOT}/stacks/${ns}"
	echo 'fixture-builder noop' >"${TEST_ROOT}/stacks/${ns}/alpha.wslb"
	echo 'fixture-builder noop' >"${TEST_ROOT}/stacks/${ns}/beta.wslb"
	run ./wsl-stacker.sh "${ns}"
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ Available\ stacks\ for\ ${ns}: ]]
	[[ "${output:?}" =~ alpha ]]
	[[ "${output:?}" =~ beta ]]
	rm -rf "${TEST_ROOT}/stacks/${ns}"
}

@test 'S2: missing stack file exits nonzero' {
	mkdir -p "${_STACKER_TMP}/empty-stacks"
	run ./wsl-stacker.sh "${_STACKER_TMP}/empty-stacks" no-such-stack
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Stack\ not\ found: ]]
}

@test 'S3: minimal stack fixture-builder noop succeeds' {
	mkdir -p "${_STACKER_TMP}/st/a"
	echo 'fixture-builder noop' >"${_STACKER_TMP}/st/a/b.wslb"
	run ./wsl-stacker.sh "${_STACKER_TMP}/st" a/b
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
}

@test 'S3b: multi-step stack prints config path once across builder children' {
	mkdir -p "${_STACKER_TMP}/st/multi"
	{
		echo 'fixture-builder noop'
		echo 'fixture-builder noop'
	} >"${_STACKER_TMP}/st/multi/two-step.wslb"
	run ./wsl-stacker.sh "${_STACKER_TMP}/st" multi/two-step
	[[ "${status:?}" -eq 0 ]]
	local using_count
	using_count="$(printf '%s\n' "${output:?}" | grep -c 'Using: ' || true)"
	[[ "${using_count:?}" -eq 1 ]]
}

@test 'S4: stack name may be passed with redundant .wslb suffix' {
	mkdir -p "${_STACKER_TMP}/st2/a"
	echo 'fixture-builder noop' >"${_STACKER_TMP}/st2/a/b.wslb"
	run ./wsl-stacker.sh "${_STACKER_TMP}/st2" a/b.wslb
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
}

@test 'S5: shorthand namespace stack resolves to stacks/<namespace>/<stack>.wslb' {
	local ns="bats_stacker_ns_${RANDOM}"
	mkdir -p "${TEST_ROOT}/stacks/${ns}"
	echo 'fixture-builder noop' >"${TEST_ROOT}/stacks/${ns}/minimal.wslb"
	run ./wsl-stacker.sh "${ns}" minimal
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
	rm -rf "${TEST_ROOT}/stacks/${ns}"
}

@test 'S6: long form when shorthand file missing (stacks directory stacks, flat stack name)' {
	local flat="bats_stacker_flat_${RANDOM}"
	echo 'fixture-builder noop' >"${TEST_ROOT}/stacks/${flat}.wslb"
	run ./wsl-stacker.sh stacks "${flat}"
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
	rm -f "${TEST_ROOT}/stacks/${flat}.wslb"
}

@test 'S7: builder children do not inherit stack file as stdin' {
	mkdir -p "${_STACKER_TMP}/st/stdin"
	{
		echo 'fixture-builder stdin-probe'
		echo 'fixture-builder noop'
	} >"${_STACKER_TMP}/st/stdin/two-step.wslb"
	run ./wsl-stacker.sh "${_STACKER_TMP}/st" stdin/two-step
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ stdin-probe\ stdin:\ \<eof\> ]]
	[[ ! "${output:?}" =~ stdin-probe\ stdin:\ fixture-builder\ noop ]]
}

@test 'S8: EXTERNAL_STACKS_ROOT symlinked namespace stack runs and prints external root' {
	local ext="${BATS_TEST_TMPDIR}/ext-stacks-root"
	local ns="bats_stacker_ext_ns_${RANDOM}"
	mkdir -p "${ext}/${ns}"
	echo 'fixture-builder noop' >"${ext}/${ns}/minimal.wslb"
	local alt_conf="${BATS_TEST_TMPDIR}/alt-wsl-builds-external-stacks.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	printf '\nEXTERNAL_STACKS_ROOT=%s\n' "${ext}" >>"${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run ./wsl-stacker.sh "${ns}" minimal
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" == *"Using: ${alt_conf}"* ]]
	[[ "${output:?}" == *"Using external stacks root: ${ext}"* ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
}

@test 'S9: EXTERNAL_STACKS_ROOT missing directory exits nonzero' {
	local missing="${BATS_TEST_TMPDIR}/no-such-ext-stacks-dir"
	local alt_conf="${BATS_TEST_TMPDIR}/alt-wsl-builds-missing-external-stacks.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	printf '\nEXTERNAL_STACKS_ROOT=%s\n' "${missing}" >>"${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run ./wsl-stacker.sh spoddycoder dev
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" == *'EXTERNAL_STACKS_ROOT is set but is not an existing directory:'* ]]
}
