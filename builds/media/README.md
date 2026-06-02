# `media`
CLI media processing tools for encoding, transcoding, and filtering audio and video on WSL2.

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `ffmpeg`
* Install the ffmpeg command-line tool from Ubuntu repositories

### `ffmpeg-dev`
* Install ffmpeg plus development libraries for building or linking against libav (codec, format, util, swscale, swresample, filter) and libx264
* Includes the ffmpeg CLI for dev workflows that need both runtime and headers

### `libprojectm`
* Builds [libprojectM](https://github.com/projectM-visualizer/projectm) from source with CMake (Ninja) and installs into a user prefix (default `~/.local`).
* At install time you choose **latest stable release** (official tarball; GitHub API resolves the tag, with fallback to v4.1.6) or **bleeding-edge git `master`** (4.2.x API including FBO rendering; no published v4.2.x release yet).
* Installs build dependencies including OpenGL/Mesa and `libsdl2-dev` (`ENABLE_SDL_UI=ON` for the dev test UI).
* Refreshes a `wsl-builds:libprojectm` block in `~/.bashrc` / `~/.zshrc` exporting `PATH`, `LD_LIBRARY_PATH`, `PKG_CONFIG_PATH`, and `CMAKE_PREFIX_PATH`.
* Verify with `pkg-config --modversion projectM-4` and confirm `projectm_opengl_render_frame_fbo` in `~/.local/include/projectM-4/render_opengl.h`.
* Optional `wsl-builds.conf` keys:
  * `LIBPROJECTM_SRC_DIR` — source tree (default `~/libprojectM` for git master; `~/libprojectM-<version>` for stable release when unset)
  * `LIBPROJECTM_INSTALL_PREFIX` — install prefix (default `~/.local`)
* With `--force` when **libprojectm** is already recorded in `~/.wsl-build.info`, you are prompted whether to remove the CMake build tree under `<src>/build` and rebuild from source (default **N**).
* The SDL test UI binary (`projectM-Test-UI`) lives under the CMake build directory; run it from WSL with [WSLg](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps).

## Build Arguments
* No additional arguments for this build
