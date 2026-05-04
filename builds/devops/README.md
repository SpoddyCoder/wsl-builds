# `devops`
Essential DevOps tools for infrastructure management and container orchestration.

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `docker`
* Installs Docker Engine, Buildx, and the Compose plugin from Docker's official repository
* Adds the current user to the `docker` group; restart WSL before running Docker without `sudo`
* After install, if **`systemd`** is available and Docker-related unit files are present, you are optionally prompted to **`systemctl disable --now`** **`docker.service`**, **`docker.socket`** (if present), and **`containerd.service`** so they stop immediately if running and do not start on boot (default **Y**)
* https://docs.docker.com/engine/install/ubuntu/

### `terraform`
* Install deps & the latest stable version from HashiCorp's official repository
* https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### `packer`
* Install deps & the latest stable version from HashiCorp's official repository
* Includes autocomplete installation for enhanced CLI experience
* https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli

### `kubectl`
* Installs the latest stable version from the official Kubernetes repository
* Includes SHA256 verification for security

### `k9s`
* Installs the latest stable version of k9s, a terminal UI for Kubernetes clusters
* Downloads and installs the official .deb package from the k9s GitHub releases
* https://github.com/derailed/k9s

### `docker-desktop`
* No install on the WSL instance, just install on the Windows host for best perfomance
* https://docs.docker.com/desktop/features/wsl/
* Use `system -> qol` to enable `autoMemoryReclaim`
