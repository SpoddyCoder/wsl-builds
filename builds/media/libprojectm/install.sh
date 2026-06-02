#!/usr/bin/env bash

printInfo "Installing libprojectM"

_pm_prefix="${LIBPROJECTM_INSTALL_PREFIX:-$HOME/.local}"
_pm_git_ref=master
_pm_repo="https://github.com/projectM-visualizer/projectm.git"
_pm_github_latest='https://api.github.com/repos/projectM-visualizer/projectm/releases/latest'
_pm_stable_fallback='4.1.6' # v4.1.6; latest stable release when GitHub API fetch fails
_pm_from_git=false
_pm_clean_build=false

if promptYesNo "Install bleeding-edge libprojectM from git master"; then
    _pm_from_git=true
fi

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
    curl \
    git \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libgl1-mesa-dev \
    mesa-common-dev \
    libsdl2-dev

_pm_version="${_pm_stable_fallback}"
if [[ "${_pm_from_git}" == false ]]; then
    if _pm_tag="$(curl -fsSL "${_pm_github_latest}" 2>/dev/null | grep -m1 '"tag_name"' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"; then
        _pm_version="${_pm_tag#v}"
    else
        printWarning "Could not fetch latest libprojectM release tag; using v${_pm_stable_fallback}"
    fi
fi

if [[ -n "${LIBPROJECTM_SRC_DIR:-}" ]]; then
    _pm_src="${LIBPROJECTM_SRC_DIR}"
elif [[ "${_pm_from_git}" == true ]]; then
    _pm_src="${HOME}/libprojectM"
else
    _pm_src="${HOME}/libprojectM-${_pm_version}"
fi
_pm_build="${_pm_src}/build"
_pm_parent="$(dirname "${_pm_src}")"
_pm_tarball_name="libprojectM-${_pm_version}.tar.gz"
_pm_tarball_url="https://github.com/projectM-visualizer/projectm/releases/download/v${_pm_version}/${_pm_tarball_name}"

if [[ "${_pm_from_git}" == true ]]; then
    if [[ -d "${_pm_src}/.git" ]]; then
        printInfo "Updating libprojectM source tree (${_pm_git_ref})"
        git -C "${_pm_src}" fetch origin --tags
        git -C "${_pm_src}" checkout "${_pm_git_ref}"
        git -C "${_pm_src}" submodule update --init --recursive
    else
        printInfo "Cloning libprojectM (${_pm_git_ref})"
        mkdir -p "${_pm_parent}"
        git clone --recursive "${_pm_repo}" "${_pm_src}"
        git -C "${_pm_src}" checkout "${_pm_git_ref}"
        git -C "${_pm_src}" submodule update --init --recursive
    fi
elif [[ ! -f "${_pm_src}/CMakeLists.txt" ]]; then
    printInfo "Downloading libprojectM ${_pm_version} release tarball"
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

replaceManagedShellRcRegion libprojectm "$(printf "export PATH=\"%s/bin:\${PATH}\"\nexport LD_LIBRARY_PATH=\"%s/lib\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}\"\nexport PKG_CONFIG_PATH=\"%s/lib/pkgconfig\${PKG_CONFIG_PATH:+:\${PKG_CONFIG_PATH}}\"\nexport CMAKE_PREFIX_PATH=\"%s\${CMAKE_PREFIX_PATH:+:\${CMAKE_PREFIX_PATH}}\"\n" "${_pm_prefix}" "${_pm_prefix}" "${_pm_prefix}" "${_pm_prefix}")"

export PATH="${_pm_prefix}/bin:${PATH}"
export LD_LIBRARY_PATH="${_pm_prefix}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export PKG_CONFIG_PATH="${_pm_prefix}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
export CMAKE_PREFIX_PATH="${_pm_prefix}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"

_pm_pkg_ver="$(pkg-config --modversion projectM-4)"
printInfo "libprojectM version: ${_pm_pkg_ver}"

_pm_render_header="${_pm_prefix}/include/projectM-4/render_opengl.h"
if [[ -f "${_pm_render_header}" ]] && grep -q 'projectm_opengl_render_frame_fbo' "${_pm_render_header}"; then
    printInfo "libprojectM FBO API available (projectm_opengl_render_frame_fbo)"
elif [[ "${_pm_from_git}" == true ]]; then
    printWarning "FBO API not found in ${_pm_render_header}; check git ref (${_pm_git_ref})"
fi

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
