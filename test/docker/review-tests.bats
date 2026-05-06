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
	cat >"${REVIEW_BUILD_DIR}/audit_review_stub.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":0,"reasons":[],"summary":"Harness OK"}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/audit_review_stub.sh"
	_bld="$(basename "${REVIEW_BUILD_DIR}")"
	run ./src/review/component-review.sh "${_bld}" review-stub
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Harness\ OK ]]
	_result="${REVIEW_BUILD_DIR}/review_review-stub.result.json"
	[[ -f "${_result}" ]]
	[[ "$(jq -r '.build' "${_result}")" == "${_bld}" ]]
	[[ "$(jq -r '.component' "${_result}")" == 'review-stub' ]]
	[[ "$(jq -r '.summary' "${_result}")" == 'Harness OK' ]]
	[[ "$(jq -r '.review_completed | endswith("Z")' "${_result}")" == 'true' ]]
}

@test 'R2: merged JSON missing required reasons array fails validation' {
	cat >"${REVIEW_BUILD_DIR}/audit_review_stub.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":0,"summary":"missing reasons"}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/audit_review_stub.sh"
	run ./src/review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Merged\ review\ JSON\ failed\ runner\ validation ]]
}

@test 'R3: merged JSON with review_result out of range fails validation' {
	cat >"${REVIEW_BUILD_DIR}/audit_review_stub.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":4,"reasons":[]}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/audit_review_stub.sh"
	run ./src/review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Merged\ review\ JSON\ failed\ runner\ validation ]]
}

@test 'R4: validation failure does not create or overwrite review_<token>.result.json' {
	printf '%s\n' '{"stale_marker":true}' >"${REVIEW_BUILD_DIR}/review_review-stub.result.json"
	cat >"${REVIEW_BUILD_DIR}/audit_review_stub.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":99,"reasons":[]}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/audit_review_stub.sh"
	run ./src/review/component-review.sh "$(basename "${REVIEW_BUILD_DIR}")" review-stub
	[[ "${status:?}" -ne 0 ]]
	[[ "$(cat "${REVIEW_BUILD_DIR}/review_review-stub.result.json")" == "$(printf '%s\n' '{"stale_marker":true}')" ]]
}

@test 'R5: successful run overwrites an existing review_<token>.result.json' {
	printf '%s\n' '{"stale_marker":true}' >"${REVIEW_BUILD_DIR}/review_review-stub.result.json"
	cat >"${REVIEW_BUILD_DIR}/audit_review_stub.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"component_reviewer_version":1,"review_result":0,"reasons":[],"summary":"Replaced"}'
EOS
	chmod +x "${REVIEW_BUILD_DIR}/audit_review_stub.sh"
	_bld="$(basename "${REVIEW_BUILD_DIR}")"
	run ./src/review/component-review.sh "${_bld}" review-stub
	[[ "${status:?}" -eq 0 ]]
	_result="${REVIEW_BUILD_DIR}/review_review-stub.result.json"
	[[ "$(jq -r 'has("stale_marker")' "${_result}")" == 'false' ]]
	[[ "$(jq -r '.summary' "${_result}")" == 'Replaced' ]]
	[[ "$(jq -r '.build' "${_result}")" == "${_bld}" ]]
}
