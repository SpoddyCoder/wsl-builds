# Harness-only: exercises getFile stale-cache prompt + refresh (Bats). Requires
# WARN_IF_CACHED_FILE_OLDER_THAN low enough that touch -d ages the seed (see test harness
# wsl-builds.conf) and WSL_BUILDS_GETFILE_STALE_EXPECT=cache|refresh for the assertion.
# shellcheck shell=bash

printInfo "Installing getfile-stale-harness"

case "${WSL_BUILDS_GETFILE_STALE_EXPECT:-}" in
	cache | refresh) ;;
	*)
		printError 'WSL_BUILDS_GETFILE_STALE_EXPECT must be cache or refresh'
		exit 1
		;;
esac

local_dl="$(mktemp -d)"
fixture_dir="$(cd "${BUILD_DIR}/fixtures" && pwd)"
readonly http_port=58842

python3 -m http.server "${http_port}" --directory "${fixture_dir}" >/dev/null 2>&1 &
http_pid=$!

cleanup_fixture() {
	kill "${http_pid}" 2>/dev/null || true
	wait "${http_pid}" 2>/dev/null || true
	rm -rf "${local_dl}"
}
trap cleanup_fixture EXIT

mkdir -p "${CACHE_DIR:?}"

cache_fn='wsl-builds-fixture-stale-cache.txt'
cache_only_payload='wsl-builds-stale-cache-hit-only'
printf '%s' "${cache_only_payload}" > "${CACHE_DIR}/${cache_fn}"
touch -d '2 days ago' "${CACHE_DIR}/${cache_fn}"

download_url="http://127.0.0.1:${http_port}/getfile-stale-src.txt"
_i=0
while ((_i < 40)); do
	if wget -q -O /dev/null --timeout=1 "${download_url}"; then
		break
	fi
	sleep 0.05
	((_i += 1))
done

getFile "${cache_fn}" "${download_url}" "${local_dl}" getfile_stale_out
expected_refresh="$(cat "${fixture_dir}/getfile-stale-src.txt")"
# shellcheck disable=SC2154 # getfile_stale_out set by getFile via nameref
actual="$(cat "${getfile_stale_out}")"

if [[ "${WSL_BUILDS_GETFILE_STALE_EXPECT}" == cache ]]; then
	if [[ "${actual}" != "${cache_only_payload}" ]]; then
		printError 'getFile stale path: expected seeded cache payload'
		exit 1
	fi
else
	if [[ "${actual}" != "${expected_refresh}" ]]; then
		printError 'getFile stale path: expected refreshed payload from fixture'
		exit 1
	fi
fi

cleanupGetFiles

# shellcheck disable=SC2154 # getfile_stale_out was set by getFile before cleanup
if [[ -f "${getfile_stale_out}" ]]; then
	printError 'cleanupGetFiles left stale-harness target file'
	exit 1
fi

printInfo 'getfile-stale-harness installed'
