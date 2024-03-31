# `biscuit-ai`
A good basic base for AI work using Python and CUDA.

* Build Options;
  * `conda`
    * Install Anaconda for Python support
  * `cuda124`
    * Install WSL version of CUDA 12.4
* Build Arguments
  * No additional arguments for this build
* Requires
  * `Ubuntu 22.04`


## Install Details
* Anaconda
  * https://www.anaconda.com/download#downloads
  * NOTE: Select YES when asked about updating environment
* CUDA 12 Support
  * IMPORTANT: always use the WSL version! Any other CUDA package installs will overwrite the wsl nvidia driver
  * https://docs.nvidia.com/cuda/wsl-user-guide/index.html
  * https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_local
  * Useful: https://forums.developer.nvidia.com/c/accelerated-computing/cuda/cuda-on-windows-subsystem-for-linux/303
