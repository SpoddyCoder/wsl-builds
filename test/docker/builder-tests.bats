#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only ./wsl-builder.sh regressions (fixture-builder harness).

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

@test 'B1: wsl-builder.sh with no arguments exits nonzero and prints usage' {
	run ./wsl-builder.sh
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ Available\ build\ directories: ]]
}

@test 'B2: unknown build directory exits nonzero' {
	run ./wsl-builder.sh '__EARLY_EXIT_UNKNOWN_BUILD_DIR__'
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ "Build directory '__EARLY_EXIT_UNKNOWN_BUILD_DIR__' not found" ]]
}

@test 'B3: single-arg fixture-builder lists components without running install pipeline' {
	run ./wsl-builder.sh fixture-builder
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ Available\ components\ for\ fixture-builder: ]]
}

@test 'B4: noop component noop-hyphen runs full harness and succeeds' {
	run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'B5: comma-separated noop-hyphen (hyphen token) and noop (plain token) dispatch' {
	run ./wsl-builder.sh fixture-builder noop,noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'B6: invalid component for fixture-builder fails' {
	run ./wsl-builder.sh fixture-builder not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'B7: --force with noop-hyphen succeeds' {
	run ./wsl-builder.sh fixture-builder noop-hyphen --force
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'B8: successful install writes ~/.wsl-build.info with OS header and component line' {
	run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	[[ -f "${info:?}" ]]
	local lines
	lines="$(wc -l < "${info}")"
	[[ "${lines// /}" -ge 2 ]]
	grep -Fxq 'fixture-builder v1.0.0 (noop-hyphen)' "${info}"
	[[ "$(head -n1 "${info}")" =~ [[:space:]] ]]
}

@test 'B9: comma-separated installs append one record line per component' {
	run ./wsl-builder.sh fixture-builder noop,noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	grep -Fxq 'fixture-builder v1.0.0 (noop)' "${info}"
	grep -Fxq 'fixture-builder v1.0.0 (noop-hyphen)' "${info}"
	[[ "$(grep -c -F 'fixture-builder v1.0.0 (noop)' "${info}")" -eq 1 ]]
	[[ "$(grep -c -F 'fixture-builder v1.0.0 (noop-hyphen)' "${info}")" -eq 1 ]]
}

@test 'B10: second install without --force skips and does not duplicate build.info lines' {
	run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ already\ listed ]]
	[[ "${output:?}" =~ No\ changes\ made ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c -F 'fixture-builder v1.0.0 (noop-hyphen)' "${info}")" -eq 1 ]]
}

@test 'B11: --force reinstall appends another identical component line to build.info' {
	run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	run ./wsl-builder.sh fixture-builder noop-hyphen --force
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c -F 'fixture-builder v1.0.0 (noop-hyphen)' "${info}")" -eq 2 ]]
}

@test 'B12: touch-marker writes sentinel file and records success in build.info' {
	run ./wsl-builder.sh fixture-builder touch-marker
	[[ "${status:?}" -eq 0 ]]
	[[ -f "${HOME}/.wsl-builds-fixture-builder-touch-marker" ]]
	grep -Fxq 'fixture-builder v1.0.0 (touch-marker)' "${HOME}/.wsl-build.info"
}

@test 'B13: default usage hides fixture builds; WSL_BUILDS_LIST_FIXTURE_BUILDS lists them' {
	run ./wsl-builder.sh
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Available\ build\ directories: ]]
	[[ "${output:?}" != *fixture-builder* ]]
	[[ "${output:?}" != *fixture-review* ]]
	WSL_BUILDS_LIST_FIXTURE_BUILDS=1 run ./wsl-builder.sh
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ [[:space:]]fixture-builder ]]
	[[ "${output:?}" =~ [[:space:]]fixture-review ]]
}

@test 'B14: too many arguments exits nonzero' {
	run ./wsl-builder.sh fixture-builder noop-hyphen extra-junk-arg
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Too\ many\ arguments ]]
}

@test 'B15: comma-separated valid then invalid component fails' {
	run ./wsl-builder.sh fixture-builder noop,not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'B16: --force alone without component fails validation' {
	run ./wsl-builder.sh fixture-builder --force
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'B17: empty component argument fails validation' {
	run ./wsl-builder.sh fixture-builder ''
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" =~ Invalid\ build\ component ]]
}

@test 'B18: component match is case-insensitive; build.info keeps canonical token' {
	run ./wsl-builder.sh fixture-builder NOOP-HYPHEN
	[[ "${status:?}" -eq 0 ]]
	grep -Fxq 'fixture-builder v1.0.0 (noop-hyphen)' "${HOME}/.wsl-build.info"
}

@test 'B19: failed validation leaves ~/.wsl-build.info absent' {
	run ./wsl-builder.sh '__EARLY_EXIT_UNKNOWN_BUILD_DIR__'
	[[ "${status:?}" -ne 0 ]]
	[[ ! -f "${HOME}/.wsl-build.info" ]]
	run ./wsl-builder.sh fixture-builder not-a-listed-component-at-all
	[[ "${status:?}" -ne 0 ]]
	[[ ! -f "${HOME}/.wsl-build.info" ]]
}

@test 'B20: multiple installs reuse single OS header line in build.info' {
	run ./wsl-builder.sh fixture-builder noop
	[[ "${status:?}" -eq 0 ]]
	run ./wsl-builder.sh fixture-builder touch-marker
	[[ "${status:?}" -eq 0 ]]
	local info="${HOME}/.wsl-build.info"
	[[ "$(grep -c '^fixture-builder v[0-9]' "${info}")" -eq 2 ]]
	[[ "$(grep -cv '^fixture-builder v[0-9]' "${info}")" -eq 1 ]]
}

@test 'B21: WSL_BUILDS_CONF set to readable file is sourced and path is printed' {
	local alt_conf="${BATS_TEST_TMPDIR}/alt-wsl-builds.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" == *"Using: ${alt_conf}"* ]]
}

@test 'B22: WSL_BUILDS_CONF set but not readable exits nonzero' {
	WSL_BUILDS_CONF="${BATS_TEST_TMPDIR}/wsl-builds-does-not-exist.conf" run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" == *'WSL_BUILDS_CONF is set but not readable:'* ]]
}

@test 'B29: without WSL_BUILDS_CONF builder sources ~/.wsl-builds.conf and prints path' {
	run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	local expected="${HOME}/.wsl-builds.conf"
	[[ "${output:?}" == *"Using: ${expected}"* ]]
}

@test 'B30: missing user config exits nonzero with configure hint' {
	rm -f "${HOME}/.wsl-builds.conf"
	run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" == *'WSL_BUILDS_CONF'* ]]
	[[ "${output:?}" == *'~/.wsl-builds.conf'* ]]
	[[ "${output:?}" == *'configure.sh'* ]]
}

@test 'B31: WSL_BUILDS_CONF takes precedence over poisonous ~/.wsl-builds.conf' {
	local alt_conf="${BATS_TEST_TMPDIR}/alt-wsl-builds-precedence.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	printf 'exit 1\n' >"${HOME}/.wsl-builds.conf"
	WSL_BUILDS_CONF="${alt_conf}" run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" == *"Using: ${alt_conf}"* ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'B32: empty WSL_BUILDS_CONF falls back to ~/.wsl-builds.conf' {
	WSL_BUILDS_CONF="" run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	local expected="${HOME}/.wsl-builds.conf"
	[[ "${output:?}" == *"Using: ${expected}"* ]]
}

@test 'B33: unreadable ~/.wsl-builds.conf exits nonzero with configure hint' {
	rm -f "${HOME}/.wsl-builds.conf"
	ln -s /wsl-builds-harness-nonexistent-conf-target "${HOME}/.wsl-builds.conf"
	run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" == *'WSL_BUILDS_CONF'* ]]
	[[ "${output:?}" == *'~/.wsl-builds.conf'* ]]
	[[ "${output:?}" == *'configure.sh'* ]]
}

@test 'B27: EXTERNAL_BUILDS_ROOT symlinked build runs install and prints external root' {
	local ext="${BATS_TEST_TMPDIR}/ext-builds-root"
	mkdir -p "${ext}"
	ln -s "${TEST_ROOT}/builds/fixture-builder" "${ext}/fixture-builder"
	local alt_conf="${BATS_TEST_TMPDIR}/alt-wsl-builds-external-root.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	printf '\nEXTERNAL_BUILDS_ROOT=%s\n' "${ext}" >>"${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" == *"Using: ${alt_conf}"* ]]
	[[ "${output:?}" == *"Using external builds root: ${ext}"* ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
}

@test 'B28: EXTERNAL_BUILDS_ROOT missing directory exits nonzero' {
	local missing="${BATS_TEST_TMPDIR}/no-such-ext-builds-dir"
	local alt_conf="${BATS_TEST_TMPDIR}/alt-wsl-builds-missing-external.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	printf '\nEXTERNAL_BUILDS_ROOT=%s\n' "${missing}" >>"${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run ./wsl-builder.sh fixture-builder noop-hyphen
	[[ "${status:?}" -ne 0 ]]
	[[ "${output:?}" == *'EXTERNAL_BUILDS_ROOT is set but is not an existing directory:'* ]]
}

@test 'B23: getfile-harness exercises getFile cache hit download cleanupGetFiles and records success' {
	run ./wsl-builder.sh fixture-builder getfile-harness
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Using\ locally\ cached\ version ]]
	[[ "${output:?}" =~ Downloading\ and\ caching ]]
	grep -Fxq 'fixture-builder v1.0.0 (getfile-harness)' "${HOME}/.wsl-build.info"
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

	run ./wsl-builder.sh fixture-builder file-edit-harness
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Building\ fixture-builder\ v1\.0\.0 ]]
	[[ "${output:?}" =~ installed! ]]
	grep -qF '[wsl-builds-fixture-builder]' /etc/wsl.conf
	grep -qF 'fixture = true' /etc/wsl.conf
	grep -qF '[wsl-builds-fixture-automount]' /etc/wsl.conf
	grep -qF '[wsl-builds-fixture-interop]' /etc/wsl.conf
	awk -v a=0 -v i=0 '
		/^\[wsl-builds-fixture-automount\]/ { in_a=1; in_i=0; next }
		/^\[wsl-builds-fixture-interop\]/ { in_i=1; in_a=0; next }
		/^\[/ { in_a=0; in_i=0; next }
		in_a && index($0, "enabled = false") { a=1 }
		in_i && index($0, "enabled = false") { i=1 }
		END { exit !(a && i) }
	' /etc/wsl.conf
	grep -qF '# harness dummy seed' /etc/wsl.conf
	grep -qF '# >>> wsl-builds:fixture-builder-file-harness >>>' "${HOME}/.bashrc"
	grep -qF 'export WSL_BUILDS_FIXTURE_BUILDER_HARNESS=1' "${HOME}/.bashrc"
	grep -qF '# <<< wsl-builds:fixture-builder-file-harness <<<' "${HOME}/.bashrc"
	grep -Fxq 'fixture-builder v1.0.0 (file-edit-harness)' "${HOME}/.wsl-build.info"
}

@test 'B25: getfile-stale-harness stale cache default yes keeps seeded payload' {
	run bash -c 'export WSL_BUILDS_GETFILE_STALE_EXPECT=cache; printf "\n" | ./wsl-builder.sh fixture-builder getfile-stale-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Cached\ wsl-builds-fixture-stale-cache\.txt\ is\ about\ [0-9]+\ days\ old\ \(stale\ after\ [0-9]+\ days\) ]]
	[[ "${output:?}" =~ Use\ cached\ file\ anyway\? ]]
	[[ "${output:?}" =~ Using\ locally\ cached\ version ]]
	grep -Fxq 'fixture-builder v1.0.0 (getfile-stale-harness)' "${HOME}/.wsl-build.info"
}

@test 'B26: getfile-stale-harness stale cache n refreshes from fixture URL' {
	run bash -c 'export WSL_BUILDS_GETFILE_STALE_EXPECT=refresh; printf "n\n" | ./wsl-builder.sh fixture-builder getfile-stale-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Cached\ wsl-builds-fixture-stale-cache\.txt\ is\ about\ [0-9]+\ days\ old\ \(stale\ after\ [0-9]+\ days\) ]]
	[[ "${output:?}" =~ Downloading\ fresh\ copy ]]
	grep -Fxq 'fixture-builder v1.0.0 (getfile-stale-harness)' "${HOME}/.wsl-build.info"
}

@test 'B34: apt-update-interval-harness default interval skips fresh indexes' {
	run bash -c 'export WSL_BUILDS_APT_UPDATE_HARNESS_MODE=ifstale WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT=skip; ./wsl-builder.sh fixture-builder apt-update-interval-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Skipping\ apt\ update\ \(package\ indexes\ were\ updated\ recently\ within\ the\ 360-minute\ interval\) ]]
	grep -Fxq 'fixture-builder v1.0.0 (apt-update-interval-harness)' "${HOME}/.wsl-build.info"
}

@test 'B35: apt-update-interval-harness zero interval always updates' {
	alt_conf="${BATS_TEST_TMPDIR}/apt-update-zero.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	printf '\nAPT_UPDATE_INTERVAL_MINS=0\n' >>"${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run bash -c 'export WSL_BUILDS_APT_UPDATE_HARNESS_MODE=ifstale WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT=update; ./wsl-builder.sh fixture-builder apt-update-interval-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" != *'Skipping apt update'* ]]
	grep -Fxq 'fixture-builder v1.0.0 (apt-update-interval-harness)' "${HOME}/.wsl-build.info"
}

@test 'B36: apt-update-interval-harness configured interval skips fresh indexes' {
	alt_conf="${BATS_TEST_TMPDIR}/apt-update-interval.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	printf '\nAPT_UPDATE_INTERVAL_MINS=120\n' >>"${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run bash -c 'export WSL_BUILDS_APT_UPDATE_HARNESS_MODE=ifstale WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT=skip; ./wsl-builder.sh fixture-builder apt-update-interval-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Skipping\ apt\ update\ \(package\ indexes\ were\ updated\ recently\ within\ the\ 120-minute\ interval\) ]]
	grep -Fxq 'fixture-builder v1.0.0 (apt-update-interval-harness)' "${HOME}/.wsl-build.info"
}

@test 'B37: apt-update-interval-harness required always updates fresh indexes' {
	run bash -c 'export WSL_BUILDS_APT_UPDATE_HARNESS_MODE=required WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT=update; ./wsl-builder.sh fixture-builder apt-update-interval-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" != *'Skipping apt update'* ]]
	grep -Fxq 'fixture-builder v1.0.0 (apt-update-interval-harness)' "${HOME}/.wsl-build.info"
}

@test 'B38: apt-update-interval-harness invalid interval warns and uses default skip' {
	alt_conf="${BATS_TEST_TMPDIR}/apt-update-invalid.conf"
	cp "${TEST_DIR}/wsl-builds.conf" "${alt_conf}"
	printf '\nAPT_UPDATE_INTERVAL_MINS=not-a-number\n' >>"${alt_conf}"
	WSL_BUILDS_CONF="${alt_conf}" run bash -c 'export WSL_BUILDS_APT_UPDATE_HARNESS_MODE=ifstale WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT=skip; ./wsl-builder.sh fixture-builder apt-update-interval-harness'
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ APT_UPDATE_INTERVAL_MINS\ must\ be\ a\ non-negative\ integer ]]
	[[ "${output:?}" =~ using\ 360 ]]
	[[ "${output:?}" =~ Skipping\ apt\ update\ \(package\ indexes\ were\ updated\ recently\ within\ the\ 360-minute\ interval\) ]]
	grep -Fxq 'fixture-builder v1.0.0 (apt-update-interval-harness)' "${HOME}/.wsl-build.info"
}

@test 'B39: system symlinks creates SYMLINK_HOST_* links under HOME' {
	mkdir -p /tmp/wsl-test-c-home-target /tmp/wsl-test-code-home-target
	run ./wsl-builder.sh system symlinks
	[[ "${status:?}" -eq 0 ]]
	[[ -L "${HOME}/c-home" ]]
	[[ "$(readlink "${HOME}/c-home")" == "/tmp/wsl-test-c-home-target" ]]
	[[ -L "${HOME}/code-home" ]]
	[[ "$(readlink "${HOME}/code-home")" == "/tmp/wsl-test-code-home-target" ]]
	[[ "${output:?}" =~ Host\ symlinks\ installed ]]
	[[ "${output:?}" =~ Creating\ host\ symlink ]]
}
