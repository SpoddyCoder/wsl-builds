#!/usr/bin/env bats
# shellcheck shell=bats

# Docker-only: /usr/local/bin helper scripts sourced from repo (see system/).

setup() {
	REPO="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
	CMD_ROOT="$(mktemp -d)"
	export WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}"
	cd "${REPO}" || return 1
}

teardown() {
	rm -rf "${CMD_ROOT:-}"
}

writeMixedUbuntuSources() {
	mkdir -p "${WSL_BUILDS_COMMAND_TEST_ROOT}/etc/apt/sources.list.d"
	cat >"${WSL_BUILDS_COMMAND_TEST_ROOT}/etc/apt/sources.list.d/ubuntu.sources" <<'EOF'
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: jammy
Components: main

Types: deb
URIs: http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/
Suites: jammy-security
Components: main
EOF
}

writeKentUbuntuSources() {
	mkdir -p "${WSL_BUILDS_COMMAND_TEST_ROOT}/etc/apt/sources.list.d"
	cat >"${WSL_BUILDS_COMMAND_TEST_ROOT}/etc/apt/sources.list.d/ubuntu.sources" <<'EOF'
Types: deb
URIs: http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/
Suites: jammy jammy-updates
Components: main

Types: deb
URIs: http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/
Suites: jammy-security
Components: main
EOF
}

writeCanonicalUbuntuSources() {
	mkdir -p "${WSL_BUILDS_COMMAND_TEST_ROOT}/etc/apt/sources.list.d"
	cat >"${WSL_BUILDS_COMMAND_TEST_ROOT}/etc/apt/sources.list.d/ubuntu.sources" <<'EOF'
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: jammy jammy-updates
Components: main

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: jammy-security
Components: main
EOF
}

@test 'C1: apt-mirror-switch with no args prints usage and current mirror' {
	writeCanonicalUbuntuSources
	run env WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}" ./system/apt-mirror-switch
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Usage: ]]
	[[ "${output:?}" =~ canonical ]]
	[[ "${output:?}" =~ uni-of-kent ]]
	[[ "${output:?}" =~ Current\ mirror:\ canonical ]]
}

@test 'C2: apt-mirror-switch classifies mixed Ubuntu archive URLs' {
	writeMixedUbuntuSources
	run env WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}" ./system/apt-mirror-switch
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Current\ mirror:\ mixed ]]
}

@test 'C3: apt-mirror-switch switches Kent ubuntu.sources to canonical (root)' {
	writeKentUbuntuSources
	run env WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}" ./system/apt-mirror-switch canonical
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Current\ mirror:\ canonical ]]
	grep -Fq 'http://archive.ubuntu.com/ubuntu/' "${CMD_ROOT}/etc/apt/sources.list.d/ubuntu.sources"
	grep -Fq 'http://security.ubuntu.com/ubuntu/' "${CMD_ROOT}/etc/apt/sources.list.d/ubuntu.sources"
}

@test 'C4: apt-mirror-switch switches canonical ubuntu.sources to uni-of-kent (root)' {
	writeCanonicalUbuntuSources
	run env WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}" ./system/apt-mirror-switch uni-of-kent
	[[ "${status:?}" -eq 0 ]]
	[[ "${output:?}" =~ Current\ mirror:\ uni-of-kent ]]
	grep -Fq 'mirrorservice.org/sites/archive.ubuntu.com/ubuntu' "${CMD_ROOT}/etc/apt/sources.list.d/ubuntu.sources"
}

@test 'C5: apt-mirror-switch rejects unknown mirror' {
	writeCanonicalUbuntuSources
	run env WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}" ./system/apt-mirror-switch not-a-mirror
	[[ "${status:?}" -eq 2 ]]
	[[ "${output:?}" =~ Unknown\ mirror ]]
}

@test 'C6: apt-mirror-switch with too many args fails' {
	writeCanonicalUbuntuSources
	run env WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}" ./system/apt-mirror-switch canonical extra
	[[ "${status:?}" -eq 1 ]]
}

@test 'C7: change-hostname with no args prints usage and fails' {
	run env WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}" ./system/change-hostname
	[[ "${status:?}" -eq 1 ]]
	[[ "${output:?}" =~ Usage: ]]
}

@test 'C8: change-hostname updates wsl.conf and hosts under test root' {
	run env WSL_BUILDS_COMMAND_TEST_ROOT="${CMD_ROOT}" ./system/change-hostname bats-test-host
	[[ "${status:?}" -eq 0 ]]
	grep -Fq 'hostname = bats-test-host' "${CMD_ROOT}/etc/wsl.conf"
	grep -Fq 'bats-test-host' "${CMD_ROOT}/etc/hosts"
}
