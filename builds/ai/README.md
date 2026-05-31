# `ai`
A good basic base for AI work using CUDA.

## Requires
* `Ubuntu 22.04` or greater
* `./wsl-builder.sh dev-python conda` recommended

For LangChain, the OpenAI Agents SDK, LangSmith, and Langfuse, use the [ai-agents](../ai-agents/) build instead.

## Build Components
### `cuda132`
* Install CUDA **13.2** toolkit via the **WSL-Ubuntu network** repo: `cuda-wsl-ubuntu.pin`, `cuda-keyring`, then `cuda-toolkit-13-2` (recommended method in the [CUDA Installation Guide for Linux — WSL](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#wsl)).
* When `/usr/local/cuda/bin` exists, refreshes a `wsl-builds:cuda-toolkit-path` block in `~/.bashrc` / `~/.zshrc` so `nvcc` and other toolkit binaries are on `PATH` in new shells (open a new terminal or `source` your rc file).
* Do not install `cuda`, `cuda-drivers`, or other meta-packages that pull the Linux GPU driver into WSL. Same rules as the WSL user guide.
* https://docs.nvidia.com/cuda/wsl-user-guide/index.html
* https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_network
* See the [CUDA section](../../README.md#cuda-integration) of the main README for more info.

### `cuda124`
* Install WSL-specific **CUDA 12.4** toolkit (local `.deb` repo), for environments that must stay on 12.4.
* When `/usr/local/cuda/bin` exists, refreshes the same `wsl-builds:cuda-toolkit-path` shell block as **cuda132** so `nvcc` is on `PATH` in new shells.
* IMPORTANT: always use the WSL version; generic Ubuntu CUDA installs can overwrite the WSL driver stub.
* https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_local
* Useful: https://forums.developer.nvidia.com/c/accelerated-computing/cuda/cuda-on-windows-subsystem-for-linux/303

### `cuda-wsl-lib-symlinks`
* Optional WSL workaround when tools warn that `libcuda.so.1 is not a symbolic link` (see [WSL#5663](https://github.com/microsoft/WSL/issues/5663#issuecomment-1068499676)). Adjusts `libcuda.so` and `libcuda.so.1` under `/usr/lib/wsl/lib` to point at the real versioned `libcuda.so.1.*` file there, then runs `ldconfig` — from **inside the distro**, not by editing `C:\Windows\System32\lxss\lib`.
* **Skips safely** if `/usr/lib/wsl/lib` is missing (non-WSL / no GPU path) or no versioned `libcuda.so.1.*` file is found. If several `libcuda.so.1.*` files exist, the script uses the first regular (non-symlink) match; inspect with `ls libcuda.so*` in that directory if you need a different one.

### `ollama`
* Install [Ollama](https://ollama.com) using the official Linux installer (`https://ollama.com/install.sh`), which downloads the matching binary for WSL2 and wires `ollama` into your PATH.
* After install, if the systemd manager is running and `/etc/systemd/system/ollama.service` is present, you are prompted whether to `systemctl disable --now ollama` so the service stops immediately if running and does not start on boot (default **Y**). Choosing **n** leaves vendor enablement as-is.
* Optional: set `OLLAMA_MODELS` in `wsl-builds.conf` to store pulled models outside the default `~/.ollama`. When set, the install creates that directory, sets ownership for the `ollama` service user when it exists, wires `EnvironmentFile` into `ollama.service` when that unit is present, and adds `/etc/profile.d/wsl-builds-ollama-models.sh` so login shells see the same value.
* https://ollama.com/download/linux

### `huggingface-cli`
* Installs the [Hugging Face Hub](https://huggingface.co/docs/huggingface_hub) CLI (`hf`) with `python3 -m pip install --user` and the official `huggingface_hub[cli]` extra. On Ubuntu 24.04 and newer, the install passes `--break-system-packages` so a user-site install works with the distro-managed Python (same idea as upstream PEP 668 guidance for explicit tooling installs).
* After install, the script prints the CLI version (`hf version` when `~/.local/bin/hf` is present; otherwise the `huggingface_hub` package version via Python).
* Ensure `~/.local/bin` is on your `PATH` in interactive shells (many Ubuntu images already include it via `/etc/skel` defaults; open a new terminal or adjust your rc file if `hf` is not found).
* Optional: set `HF_HOME` and/or `HF_HUB_CACHE` in `wsl-builds.conf` to keep Hub config and/or the model cache on a host path. When either is set (non-empty), the install creates the directory with `0755`, `chown` to your user (same owner pattern as **ollama** when no dedicated service user applies), writes `/etc/profile.d/wsl-builds-huggingface-env.sh` exporting only the variables you set (quoted with `%q` for safe login shells), and sets `0644` on that snippet.

### `llama-cpp`
* Installs build dependencies including `libssl-dev` so CMake can enable HTTPS/TLS (e.g. downloading models from URLs).
* Clone [llama.cpp](https://github.com/ggml-org/llama.cpp), configure with CMake (Ninja), and install release binaries into your prefix (default `~/.local/bin`). Re-runs `git pull` when the clone already exists. Source tree defaults to `~/llama.cpp`.
* If `nvcc` is on `PATH` (after **cuda124** / **cuda132**, use a new shell or `source` your rc so the `cuda-toolkit-path` block applies), the build enables **GGML_CUDA**. Otherwise you get a CPU-only build; install a CUDA component first, then run this component again with `--force` if you need GPU support.
* With `--force` when **llama-cpp** is already recorded in `~/.wsl-build.info`, you are prompted whether to remove the CMake build tree under `~/llama.cpp/build` (or `LLAMA_CPP_SRC_DIR/build`) and rebuild from source (default **N** keeps the existing build tree and runs an incremental rebuild after `git pull`).
* The install sets CMake `INSTALL_RPATH` to the prefix `lib` directory and refreshes a `wsl-builds:llama-cpp` block in `~/.bashrc` / `~/.zshrc` so the prefix `bin` is on `PATH` and `lib` is on `LD_LIBRARY_PATH` (shared libraries such as `libllama-common.so`).

## Build Arguments
* No additional arguments for this build
