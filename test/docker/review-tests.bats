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
}

teardown() {
	rm -rf "${REVIEW_BUILD_DIR:-}"
	rm -rf "${_BATS_FAKE_HOME:-}"
}

@test 'R1: component-review accepts audit JSON merged with runner fields' {
	cat >"${REVIEW_BUILD_DIR}/review_stub_audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":0,"review_result_label":"Checks ran; no issues found.","review_concerns":{"security":false,"freshness":false},"reasons":[],"summary":"Harness OK"}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/review_stub_audit.sh"
	_bld="$(basename "${REVIEW_BUILD_DIR}")"
	run ./src/review/component-review.sh "${_bld}" review-stub
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Harness\ OK ]]
	_result="${REVIEW_BUILD_DIR}/review_stub_review.result.json"
	[[ -f "${_result}" ]]
	[[ "$(jq -r '.build' "${_result}")" == "${_bld}" ]]
	[[ "$(jq -r '.component' "${_result}")" == 'review-stub' ]]
	[[ "$(jq -r '.summary' "${_result}")" == 'Harness OK' ]]
	[[ "$(jq -r '.review_completed | endswith("Z")' "${_result}")" == 'true' ]]
	[[ "$(jq -r '.review_concerns.security' "${_result}")" == 'false' ]]
}

@test 'R2: merged JSON missing required reasons array fails validation' {
	cat >"${REVIEW_BUILD_DIR}/review_stub_audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":0,"summary":"missing reasons"}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/review_stub_audit.sh"
	run ./src/review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Merged\ review\ JSON\ failed\ runner\ validation ]]
}

@test 'R3: merged JSON with review_result out of range fails validation' {
	cat >"${REVIEW_BUILD_DIR}/review_stub_audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":4,"review_result_label":"Checks ran; no issues found.","review_concerns":{"security":false,"freshness":false},"reasons":[]}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/review_stub_audit.sh"
	run ./src/review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Merged\ review\ JSON\ failed\ runner\ validation ]]
}

@test 'R3b: legacy review_result 3 fails validation' {
	cat >"${REVIEW_BUILD_DIR}/review_stub_audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":3,"review_result_label":"Checks did not complete successfully (runner error, upstream unreachable, unsupported case, unknown).","review_concerns":{"security":false,"freshness":false},"reasons":[]}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/review_stub_audit.sh"
	run ./src/review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Merged\ review\ JSON\ failed\ runner\ validation ]]
}

@test 'R4: validation failure does not create or overwrite <slug>_review.result.json' {
	printf '%s\n' '{"stale_marker":true}' >"${REVIEW_BUILD_DIR}/review_stub_review.result.json"
	cat >"${REVIEW_BUILD_DIR}/review_stub_audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":99,"reasons":[]}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/review_stub_audit.sh"
	run ./src/review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "$(cat "${REVIEW_BUILD_DIR}/review_stub_review.result.json")" == "$(printf '%s\n' '{"stale_marker":true}')" ]]
}

@test 'R5: successful run overwrites an existing <slug>_review.result.json' {
	printf '%s\n' '{"stale_marker":true}' >"${REVIEW_BUILD_DIR}/review_stub_review.result.json"
	cat >"${REVIEW_BUILD_DIR}/review_stub_audit.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":0,"review_result_label":"Checks ran; no issues found.","review_concerns":{"security":false,"freshness":false},"reasons":[],"summary":"Replaced"}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/review_stub_audit.sh"
	_bld="$(basename "${REVIEW_BUILD_DIR}")"
	run ./src/review/component-review.sh "${_bld}" review-stub
	[[ "${status:?}" -eq 0 ]]
	_result="${REVIEW_BUILD_DIR}/review_stub_review.result.json"
	[[ "$(jq -r 'has("stale_marker")' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.summary' "${_result}")" == 'Replaced' ]]
	[[ "$(jq -r '.build' "${_result}")" == "${_bld}" ]]
}

@test 'R6: reviewAggregateFromChecks sets both concern flags when issues span buckets' {
	# shellcheck source=/dev/null
	source "${TEST_ROOT}/src/review/review-aggregation.sh"
	_checks='[{"audit_check_id":"a","outcome":"issue","finding_kind":"security","detail":"s"},{"audit_check_id":"b","outcome":"issue","finding_kind":"staleness","detail":"f"}]'
	_out="$(reviewAggregateFromChecks "${_checks}" '[]' '')"
	[[ "$(jq -r '.review_result' <<<"${_out}")" == '1' ]]
	[[ "$(jq -r '.review_concerns.security' <<<"${_out}")" == 'true' ]]
	[[ "$(jq -r '.review_concerns.freshness' <<<"${_out}")" == 'true' ]]
}

@test 'R7: routes_by_audit_check_id none excludes issue from concern rollup' {
	# shellcheck source=/dev/null
	source "${TEST_ROOT}/src/review/review-aggregation.sh"
	_checks='[{"audit_check_id":"x","outcome":"issue","finding_kind":"custom","detail":"d"}]'
	_policy='{"routes_by_audit_check_id":{"x":"none"}}'
	_out="$(reviewAggregateFromChecks "${_checks}" '[]' "${_policy}")"
	[[ "$(jq -r '.review_result' <<<"${_out}")" == '0' ]]
	[[ "$(jq -r '.review_concerns.security' <<<"${_out}")" == 'false' ]]
}
