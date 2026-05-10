#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only automated builds review: component-review.sh merge-then-validate (spec Phase 1 runner).

setup() {
	TEST_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
	TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
	_BATS_FAKE_HOME="$(mktemp -d)"
	export HOME="$_BATS_FAKE_HOME"
	cd "$TEST_ROOT" || return 1
	/bin/cp -f "${TEST_DIR}/wsl-builds.conf" "${HOME}/.wsl-builds.conf"
	REVIEW_BUILD_DIR="$(mktemp -d "${TEST_ROOT}/builds/.bats-review.XXXXXX")"
	: >"${REVIEW_BUILD_DIR}/conf.sh"
	REVIEW_SLUG_DIR="${REVIEW_BUILD_DIR}/review_stub"
	mkdir -p "${REVIEW_SLUG_DIR}"
}

teardown() {
	rm -rf "${REVIEW_BUILD_DIR:-}"
	rm -rf "${_BATS_FAKE_HOME:-}"
}

@test 'R1: component-review accepts measurement JSON merged with runner fields' {
	cat >"${REVIEW_SLUG_DIR}/audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"checks":[],"required_check_ids":[]}'
EOS
	chmod +x "${REVIEW_SLUG_DIR}/audit.sh"
	_bld="$(basename "${REVIEW_BUILD_DIR}")"
	run ./review/component-review.sh "${_bld}" review-stub
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Wrote ]]
	_result="${REVIEW_SLUG_DIR}/review.result.json"
	[[ -f "${_result}" ]]
	[[ "$(jq -r '.build' "${_result}")" == "${_bld}" ]]
	[[ "$(jq -r '.component' "${_result}")" == 'review-stub' ]]
	[[ "$(jq -r '.concerns.skipped' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.review_completed | endswith("Z")' "${_result}")" == 'true' ]]
	[[ "$(jq -r 'has("required_check_ids")' "${_result}")" == 'false' ]]
}

@test 'R2: audit stdout carrying policy-view fields fails validation' {
	cat >"${REVIEW_SLUG_DIR}/audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"checks":[],"required_check_ids":[],"summary":"nope"}'
EOS
	chmod +x "${REVIEW_SLUG_DIR}/audit.sh"
	run ./review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Audit\ stdout\ failed\ measurement\ JSON\ validation ]]
}

@test 'R3: audit stdout with forbidden verdict-style field fails validation' {
	cat >"${REVIEW_SLUG_DIR}/audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"checks":[{"audit_check_id":"x","outcome":"passed","detail":"ok"}],"required_check_ids":["x"],"review_result":1}'
EOS
	chmod +x "${REVIEW_SLUG_DIR}/audit.sh"
	run ./review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Audit\ stdout\ failed\ measurement\ JSON\ validation ]]
}

@test 'R3b: audit stdout missing checks array fails validation' {
	cat >"${REVIEW_SLUG_DIR}/audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"required_check_ids":[]}'
EOS
	chmod +x "${REVIEW_SLUG_DIR}/audit.sh"
	run ./review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Audit\ stdout\ failed\ measurement\ JSON\ validation ]]
}

@test 'R4: validation failure does not create or overwrite <slug>/review.result.json' {
	printf '%s\n' '{"stale_marker":true}' >"${REVIEW_SLUG_DIR}/review.result.json"
	cat >"${REVIEW_SLUG_DIR}/audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"checks":[],"review_result":0}'
EOS
	chmod +x "${REVIEW_SLUG_DIR}/audit.sh"
	run ./review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "$(cat "${REVIEW_SLUG_DIR}/review.result.json")" == "$(printf '%s\n' '{"stale_marker":true}')" ]]
}

@test 'R5: successful run overwrites an existing <slug>/review.result.json' {
	printf '%s\n' '{"stale_marker":true}' >"${REVIEW_SLUG_DIR}/review.result.json"
	cat >"${REVIEW_SLUG_DIR}/audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"checks":[],"required_check_ids":[]}'
EOS
	chmod +x "${REVIEW_SLUG_DIR}/audit.sh"
	_bld="$(basename "${REVIEW_BUILD_DIR}")"
	run ./review/component-review.sh "${_bld}" review-stub
	[[ "${status:?}" -eq 0 ]]
	_result="${REVIEW_SLUG_DIR}/review.result.json"
	[[ "$(jq -r 'has("stale_marker")' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.concerns.skipped' "${_result}")" == 'false' ]]
	[[ "$(jq -r 'has("evidence")' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.build' "${_result}")" == "${_bld}" ]]
}

@test 'R5b: top-level evidence on audit stdout fails validation' {
	cat >"${REVIEW_SLUG_DIR}/audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"checks":[],"required_check_ids":[],"evidence":{}}'
EOS
	chmod +x "${REVIEW_SLUG_DIR}/audit.sh"
	run ./review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Audit\ stdout\ failed\ measurement\ JSON\ validation ]]
}

@test 'R6: emitConcernsFromChecks sets security and freshness when issues span buckets' {
	# shellcheck source=/dev/null
	source "${TEST_ROOT}/src/review/checks-rollup.sh"
	_checks='[{"audit_check_id":"a","outcome":"issue","finding_kind":"security","detail":"s"},{"audit_check_id":"b","outcome":"issue","finding_kind":"staleness","detail":"f"}]'
	_out="$(emitConcernsFromChecks "${_checks}" '[]' '')"
	[[ "$(jq -r '.security' <<<"${_out}")" == 'true' ]]
	[[ "$(jq -r '.freshness' <<<"${_out}")" == 'true' ]]
	[[ "$(jq -r '.skipped' <<<"${_out}")" == 'false' ]]
	[[ "$(jq -r '.incomplete' <<<"${_out}")" == 'false' ]]
}

@test 'R7: routes_by_audit_check_id none excludes issue from security/freshness flags' {
	# shellcheck source=/dev/null
	source "${TEST_ROOT}/src/review/checks-rollup.sh"
	_checks='[{"audit_check_id":"x","outcome":"issue","finding_kind":"custom","detail":"d"}]'
	_policy='{"routes_by_audit_check_id":{"x":"none"}}'
	_out="$(emitConcernsFromChecks "${_checks}" '[]' "${_policy}")"
	[[ "$(jq -r '.security' <<<"${_out}")" == 'false' ]]
	[[ "$(jq -r '.freshness' <<<"${_out}")" == 'false' ]]
	[[ "$(jq -r '.incomplete' <<<"${_out}")" == 'false' ]]
}
