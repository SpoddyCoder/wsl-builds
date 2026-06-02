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
* Downloads and builds [libprojectM](https://github.com/projectM-visualizer/projectm) from the official release tarball (default version `4.1.6`) with CMake (Ninja) and installs into a user prefix (default `~/.local`).
* Installs build dependencies including OpenGL/Mesa and `libsdl2-dev` so the optional SDL test UI can be built (`ENABLE_SDL_UI=ON`).
* Refreshes a `wsl-builds:libprojectm` block in `~/.bashrc` / `~/.zshrc` exporting `PATH`, `LD_LIBRARY_PATH`, `PKG_CONFIG_PATH`, and `CMAKE_PREFIX_PATH` for the install prefix.
* Verify with `pkg-config --modversion projectM-4` (pkg-config module name is `projectM-4`, not `libprojectM`).
* Optional `wsl-builds.conf` keys: `LIBPROJECTM_VERSION`, `LIBPROJECTM_SRC_DIR` (extracted source tree, default `~/libprojectM-<version>`), `LIBPROJECTM_INSTALL_PREFIX` (default `~/.local`).
* With `--force` when **libprojectm** is already recorded in `~/.wsl-build.info`, you are prompted whether to remove the CMake build tree under `<src>/build` and rebuild from source (default **N** keeps the existing build tree for an incremental rebuild).
* The SDL test UI binary (`projectM-Test-UI`) is built under the CMake build directory; run it from WSL with [WSLg](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps) so the window can display.

## Build Arguments
* No additional arguments for this build
