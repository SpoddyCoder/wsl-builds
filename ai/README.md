# `ai`
A good basic base for AI work using CUDA.

## Requires
* `Ubuntu 22.04` or greater
* `./build.sh dev-python conda` recommended

## Build Components
### `cuda132`
* Install CUDA **13.2** toolkit via the **WSL-Ubuntu network** repo: `cuda-wsl-ubuntu.pin`, `cuda-keyring`, then `cuda-toolkit-13-2` (recommended method in the [CUDA Installation Guide for Linux — WSL](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#wsl)).
* Do not install `cuda`, `cuda-drivers`, or other meta-packages that pull the Linux GPU driver into WSL. Same rules as the WSL user guide.
* https://docs.nvidia.com/cuda/wsl-user-guide/index.html
* https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_network

### `cuda124`
* Install WSL-specific **CUDA 12.4** toolkit (local `.deb` repo), for environments that must stay on 12.4.
* IMPORTANT: always use the WSL version; generic Ubuntu CUDA installs can overwrite the WSL driver stub.
* https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_local
* Useful: https://forums.developer.nvidia.com/c/accelerated-computing/cuda/cuda-on-windows-subsystem-for-linux/303

## Build Arguments
* No additional arguments for this build
