#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only scenario tests for the review-fixture build.
# Single source: builds/review-fixture/<slug>/audit.sh — deterministic offline scenarios consumed
# by both this Bats suite and src/review/review-debug.sh (the maintainer debug harness).

setup() {
	TEST_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
	TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
	_BATS_FAKE_HOME="$(mktemp -d)"
	export HOME="$_BATS_FAKE_HOME"
	cd "$TEST_ROOT" || return 1
	/bin/cp -f "${TEST_DIR}/wsl-builds.conf" "${HOME}/.wsl-builds.conf"
}

teardown() {
	rm -rf "${_BATS_FAKE_HOME:-}"
}

@test 'RF1: happy-path persists facts-only result with all concerns false' {
	run ./src/review/component-review.sh review-fixture happy-path
	[[ "${status:?}" -eq 0 ]]
	_result="${TEST_ROOT}/builds/review-fixture/happy_path/review.result.json"
	[[ -f "${_result}" ]]
	[[ "$(jq -r '.build' "${_result}")" == 'review-fixture' ]]
	[[ "$(jq -r '.component' "${_result}")" == 'happy-path' ]]
	[[ "$(jq -r '.concerns.security' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.freshness' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.skipped' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.incomplete' "${_result}")" == 'false' ]]
	[[ "$(jq -r 'has("required_check_ids")' "${_result}")" == 'false' ]]
	[[ "$(jq -r 'has("custom_issue_policy")' "${_result}")" == 'false' ]]
}

@test 'RF2: incomplete-required forces concerns.incomplete=true' {
	run ./src/review/component-review.sh review-fixture incomplete-required
	[[ "${status:?}" -eq 0 ]]
	_result="${TEST_ROOT}/builds/review-fixture/incomplete_required/review.result.json"
	[[ -f "${_result}" ]]
	[[ "$(jq -r '.concerns.incomplete' "${_result}")" == 'true' ]]
	[[ "$(jq -r '.concerns.security' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.freshness' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.skipped' "${_result}")" == 'false' ]]
}

@test 'RF3: issue-routed sets concerns.security and concerns.freshness' {
	run ./src/review/component-review.sh review-fixture issue-routed
	[[ "${status:?}" -eq 0 ]]
	_result="${TEST_ROOT}/builds/review-fixture/issue_routed/review.result.json"
	[[ -f "${_result}" ]]
	[[ "$(jq -r '.concerns.security' "${_result}")" == 'true' ]]
	[[ "$(jq -r '.concerns.freshness' "${_result}")" == 'true' ]]
	[[ "$(jq -r '.concerns.incomplete' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.skipped' "${_result}")" == 'false' ]]
}

@test 'RF4: policy-none-route excludes custom issue from security/freshness without forcing incomplete' {
	run ./src/review/component-review.sh review-fixture policy-none-route
	[[ "${status:?}" -eq 0 ]]
	_result="${TEST_ROOT}/builds/review-fixture/policy_none_route/review.result.json"
	[[ -f "${_result}" ]]
	[[ "$(jq -r '.concerns.security' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.freshness' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.incomplete' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.skipped' "${_result}")" == 'false' ]]
}

@test 'RF5: skipped-only sets concerns.skipped=true and other concerns false' {
	run ./src/review/component-review.sh review-fixture skipped-only
	[[ "${status:?}" -eq 0 ]]
	_result="${TEST_ROOT}/builds/review-fixture/skipped_only/review.result.json"
	[[ -f "${_result}" ]]
	[[ "$(jq -r '.concerns.skipped' "${_result}")" == 'true' ]]
	[[ "$(jq -r '.concerns.security' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.freshness' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.incomplete' "${_result}")" == 'false' ]]
}

@test 'RF6: validation-fail audit stdout fails validation and writes no result.json' {
	_result="${TEST_ROOT}/builds/review-fixture/validation_fail/review.result.json"
	rm -f "${_result}"
	run ./src/review/component-review.sh review-fixture validation-fail
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Audit\ stdout\ failed\ measurement\ JSON\ validation ]]
	[[ ! -f "${_result}" ]]
}

@test 'RF7: review-debug.sh --help prints usage and exits 0' {
	run ./src/review/review-debug.sh --help
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Usage:\ review-debug.sh ]]
	[[ "${output:?}" =~ run-e2e ]]
}

@test 'RF8: review-debug.sh run-e2e happy-path --show-concerns succeeds and prints concerns keys' {
	run ./src/review/review-debug.sh run-e2e --component happy-path --show-concerns --pretty
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Derived\ concerns ]]
	[[ "${output:?}" =~ \"security\" ]]
	[[ "${output:?}" =~ \"freshness\" ]]
	[[ "${output:?}" =~ \"skipped\" ]]
	[[ "${output:?}" =~ \"incomplete\" ]]
}

@test 'RF9: review-debug.sh run-e2e validation-fail exits non-zero with diagnostic' {
	run ./src/review/review-debug.sh run-e2e --component validation-fail
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Audit\ stdout\ failed\ measurement\ JSON\ validation ]]
}
