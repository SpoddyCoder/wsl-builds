# Harness-only: exercises aptUpdateIfStale / aptUpdateRequired (Bats). Set
# WSL_BUILDS_APT_UPDATE_HARNESS_MODE=ifstale|required and
# WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT=skip|update for the assertion.
# shellcheck shell=bash

printInfo "Installing apt-update-interval-harness"

case "${WSL_BUILDS_APT_UPDATE_HARNESS_MODE:-}" in
	ifstale | required) ;;
	*)
		printError 'WSL_BUILDS_APT_UPDATE_HARNESS_MODE must be ifstale or required'
		exit 1
		;;
esac

case "${WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT:-}" in
	skip | update) ;;
	*)
		printError 'WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT must be skip or update'
		exit 1
		;;
esac

stub_dir="$(mktemp -d)"
apt_stub_log="${stub_dir}/apt-invocations.log"
export WSL_BUILDS_APT_STUB_LOG="${apt_stub_log}"

mkdir -p "${stub_dir}/bin"

cat >"${stub_dir}/bin/apt" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == update ]]; then
	printf 'update\n' >>"${WSL_BUILDS_APT_STUB_LOG:?}"
	exit 0
fi
exec /usr/bin/apt "$@"
EOF

cat >"${stub_dir}/bin/sudo" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == apt ]]; then
	shift
	exec "${stub_dir}/bin/apt" "\$@"
fi
exec /usr/bin/sudo "\$@"
EOF

chmod +x "${stub_dir}/bin/apt" "${stub_dir}/bin/sudo"
export PATH="${stub_dir}/bin:${PATH}"

cleanup_fixture() {
	rm -rf "${stub_dir}"
}
trap cleanup_fixture EXIT

mkdir -p "${CACHE_DIR:?}"
stamp="$(aptUpdateStampPath)"

if [[ "${WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT}" == skip ]]; then
	touch "${stamp}"
	if [[ -d /var/lib/apt/lists ]]; then
		touch /var/lib/apt/lists
	fi
else
	touch -d '2 days ago' "${stamp}"
	if [[ -d /var/lib/apt/lists ]]; then
		touch -d '2 days ago' /var/lib/apt/lists
	fi
fi

if [[ "${WSL_BUILDS_APT_UPDATE_HARNESS_MODE}" == ifstale ]]; then
	aptUpdateIfStale
else
	aptUpdateRequired
fi

if [[ "${WSL_BUILDS_APT_UPDATE_INTERVAL_EXPECT}" == skip ]]; then
	if [[ -f "${apt_stub_log}" ]]; then
		printError 'apt update should have been skipped'
		exit 1
	fi
else
	if [[ ! -s "${apt_stub_log}" ]]; then
		printError 'apt update should have run'
		exit 1
	fi
fi

printInfo 'apt-update-interval-harness installed'
