# Harness-only component (automated testing): exercises getFile + cleanupGetFiles.
# GNU wget in the test image rejects file:// URLs, so the download branch uses a
# short-lived localhost HTTP server (python3 -m http.server) for the fixture payload.
# shellcheck shell=bash

printInfo "Installing getfile-harness"

local_dl="$(mktemp -d)"
fixture_dir="$(cd "${BUILD_DIR}/fixtures" && pwd)"
readonly http_port=58841

python3 -m http.server "${http_port}" --directory "${fixture_dir}" >/dev/null 2>&1 &
http_pid=$!

cleanup_fixture() {
	kill "${http_pid}" 2>/dev/null || true
	wait "${http_pid}" 2>/dev/null || true
	rm -rf "${local_dl}"
}
trap cleanup_fixture EXIT

mkdir -p "${CACHE_DIR:?}"

cache_payload='wsl-builds-fixture-getfile-cache-payload'
cache_fn='wsl-builds-fixture-getfile-cache.txt'
printf '%s' "${cache_payload}" > "${CACHE_DIR}/${cache_fn}"

getFile "${cache_fn}" 'http://127.0.0.1:9/unused-on-cache-hit' "${local_dl}" getfile_cache_out
# shellcheck disable=SC2154 # set by getFile via nameref
if [[ "$(cat "${getfile_cache_out}")" != "${cache_payload}" ]]; then
	printError 'getFile cache-hit content mismatch'
	exit 1
fi

download_fn='wsl-builds-fixture-getfile-download.txt'
rm -f "${CACHE_DIR}/${download_fn}"

download_url="http://127.0.0.1:${http_port}/getfile-download-src.txt"
_i=0
while ((_i < 40)); do
	if wget -q -O /dev/null --timeout=1 "${download_url}"; then
		break
	fi
	sleep 0.05
	((_i += 1))
done

getFile "${download_fn}" "${download_url}" "${local_dl}" getfile_download_out
expected_download="$(cat "${fixture_dir}/getfile-download-src.txt")"
# shellcheck disable=SC2154 # getfile_download_out set by getFile via nameref
if [[ "$(cat "${getfile_download_out}")" != "${expected_download}" ]]; then
	printError 'getFile download content mismatch'
	exit 1
fi

cleanupGetFiles

if [[ -f "${getfile_cache_out}" ]]; then
	printError 'cleanupGetFiles left cache-hit target file'
	exit 1
fi
if [[ -f "${getfile_download_out}" ]]; then
	printError 'cleanupGetFiles left download target file'
	exit 1
fi

printInfo 'getfile-harness installed'
