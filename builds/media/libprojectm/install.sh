#!/usr/bin/env bash

printInfo "Installing libprojectM"

_pm_version="${LIBPROJECTM_VERSION:-4.1.6}"
_pm_src="${LIBPROJECTM_SRC_DIR:-$HOME/libprojectM-${_pm_version}}"
_pm_prefix="${LIBPROJECTM_INSTALL_PREFIX:-$HOME/.local}"
_pm_build="${_pm_src}/build"
_pm_parent="$(dirname "${_pm_src}")"
_pm_tarball_name="libprojectM-${_pm_version}.tar.gz"
_pm_tarball_url="https://github.com/projectM-visualizer/projectm/releases/download/v${_pm_version}/${_pm_tarball_name}"
_pm_clean_build=false

if (isBuildForced "$@"); then
    _pm_install_check_args=()
    for _pm_arg in "$@"; do
        [[ "${_pm_arg}" == "--force" ]] && continue
        _pm_install_check_args+=("${_pm_arg}")
    done
    if isComponentInstalled "libprojectm" "${_pm_install_check_args[@]}"; then
        if promptYesNoDefaultNo "Existing libprojectm install detected. Remove the build tree and rebuild from source"; then
            _pm_clean_build=true
        fi
    fi
fi

printInfo "Installing build dependencies"
aptUpdateIfStale
sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libgl1-mesa-dev \
    mesa-common-dev \
    libsdl2-dev

if [[ ! -f "${_pm_src}/CMakeLists.txt" ]]; then
    printInfo "Downloading libprojectM ${_pm_version} source"
    getFile "${_pm_tarball_name}" "${_pm_tarball_url}" "/tmp" libprojectm_tarball
    mkdir -p "${_pm_parent}"
    # shellcheck disable=SC2154 # libprojectm_tarball set by getFile via nameref
    tar -xzf "${libprojectm_tarball}" -C "${_pm_parent}"
    cleanupGetFiles
    if [[ ! -f "${_pm_src}/CMakeLists.txt" ]]; then
        printError "Expected source tree at ${_pm_src} after extracting ${_pm_tarball_name}"
        exit 1
    fi
fi

if [[ "${_pm_clean_build}" == true ]]; then
    printInfo "Removing libprojectM build directory for clean rebuild"
    rm -rf "${_pm_build}"
fi

printInfo "Configuring and building libprojectM (this may take a while)"
cmake -S "${_pm_src}" -B "${_pm_build}" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${_pm_prefix}" \
    -DCMAKE_INSTALL_RPATH="${_pm_prefix}/lib" \
    -DENABLE_SDL_UI=ON
cmake --build "${_pm_build}" -j"$(nproc)"
cmake --install "${_pm_build}"

replaceManagedShellRcRegion libprojectm "$(printf 'export PATH="%s/bin:${PATH}"\nexport LD_LIBRARY_PATH="%s/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"\nexport PKG_CONFIG_PATH="%s/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"\nexport CMAKE_PREFIX_PATH="%s${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"\n' "${_pm_prefix}" "${_pm_prefix}" "${_pm_prefix}" "${_pm_prefix}")"

export PATH="${_pm_prefix}/bin:${PATH}"
export LD_LIBRARY_PATH="${_pm_prefix}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export PKG_CONFIG_PATH="${_pm_prefix}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
export CMAKE_PREFIX_PATH="${_pm_prefix}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"

_pm_pkg_ver="$(pkg-config --modversion projectM-4)"
printInfo "libprojectM version: ${_pm_pkg_ver}"

_pm_test_ui=""
for _pm_candidate in \
    "${_pm_build}/src/sdl-test-ui/projectM-Test-UI" \
    "${_pm_build}/projectM-Test-UI" \
    "${_pm_build}/bin/projectM-Test-UI"; do
    if [[ -x "${_pm_candidate}" ]]; then
        _pm_test_ui="${_pm_candidate}"
        break
    fi
done
if [[ -n "${_pm_test_ui}" ]]; then
    printInfo "SDL test UI binary: ${_pm_test_ui} (requires WSLg for display)"
fi

printInfo "libprojectM installed"
