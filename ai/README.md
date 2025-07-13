# `ai`
A good basic base for AI work using CUDA.

## Requires
* `Ubuntu 22.04` or greater
* `./biscuit dev-python conda` recommended

## Build Components
### `cuda124`
* Install WSL-specific version of CUDA 12.4 toolkit for GPU computing support
* IMPORTANT: always use the WSL version! Any other CUDA package installs will overwrite the wsl nvidia driver
* https://docs.nvidia.com/cuda/wsl-user-guide/index.html
* https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_local
* Useful: https://forums.developer.nvidia.com/c/accelerated-computing/cuda/cuda-on-windows-subsystem-for-linux/303

## Build Arguments
* No additional arguments for this build
