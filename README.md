# WSL Builds
[![Lint](https://github.com/SpoddyCoder/wsl-builds/actions/workflows/lint.yml/badge.svg)](https://github.com/SpoddyCoder/wsl-builds/actions/workflows/lint.yml)
[![Tests](https://github.com/SpoddyCoder/wsl-builds/actions/workflows/test.yml/badge.svg)](https://github.com/SpoddyCoder/wsl-builds/actions/workflows/test.yml)

This project contains clean, simple WSL2 builds that use Windows host native implementations of core components for maximum performance, convenience and flexibility. 

* Stack components to create different WSL builds for different purposes.
* Simple installations, often featuring quality of life configurations and helpers
* Caching of large downloads on the Windows host, so you don't have to re-download install packages for rebuilds
* Other build specific cache directories on the Windows host for convenience (eg: AI models and .pkl cache)
* **Project motivation:** WSL instances are disposable - streamlines a clean rebuild whenever its needed

## Install
After provisioning a basic WSL instance, clone the project repo on it...
```
git clone https://github.com/SpoddyCoder/wsl-builds.git
```

### Configure
Run the configure wizard to create a `wsl-builds.conf` from the template...
```
cd wsl-builds
./configure.sh
```
* `./wsl-builder.sh` loads config in this order: `WSL_BUILDS_CONF` (full path) if set, else `~/.wsl-builds.conf`.
* On the Windows host, a shared file under `%USERPROFILE%\.wsl-builds\wsl-builds.conf` is useful across distros; choosing it in the wizard saves `export WSL_BUILDS_CONF=…` in your shell rc.
* Otherwise the wizard creates `~/.wsl-builds.conf` on the WSL instance (from [wsl-builds.conf.example](wsl-builds.conf.example) in the repo).
* The `wsl-builds.conf` file contains **optional** paths and settings
  * See the [wsl-builds.conf.example](wsl-builds.conf.example) for more info on each setting.
  * Optional `EXTERNAL_BUILDS_ROOT` (see example file) lets `./wsl-builder.sh` use a stack tree outside the repo instead of `builds/<name>/` here.
  * Tip: Caching things on the host can be uesful.
* **Non-interactive:** `./configure.sh --noninteractive` — no prompts; if the default Windows host `wsl-builds.conf` already exists it is adopted (`WSL_BUILDS_CONF` in shell rc), otherwise the wizard copies [wsl-builds.conf.example](wsl-builds.conf.example) to `~/.wsl-builds.conf` when that file is missing (same behavior when stdin is not a terminal, e.g. `./configure.sh </dev/null`).

## Building
By default each stack’s `conf.sh`, `install.sh`, and components live under `builds/<name>/` in this repo (`EXTERNAL_BUILDS_ROOT` in `wsl-builds.conf` can point at another directory with the same layout). Pass only `<name>` (the basename) to `./wsl-builder.sh`.
```
./wsl-builder.sh <build-dir> <component>[,<component>...] [additionalargs]... [--force]
```
* `build-dir` is the basename of a stack directory (default `builds/<name>/` in this repo, or `<name>/` under `EXTERNAL_BUILDS_ROOT` when set — see [Build List](#build-list)).
* `component[,<component>...]` comma separated list of build components (packages to install etc.), varies per build.
* `additionalargs...` additional arguments required for some builds
* `--force` by default components that are already installed will be skipped with warning messages. Use this flag to force reinstallation of already-installed components.
* The builder should be run as your current user, but some components will run commands that require escalated privileges using `sudo`
* It is not designed to be used non-interactively, some installs need user input / confirmation.

### Assembling and Stacking Builds
```bash
./wsl-builder.sh            # show all builds
./wsl-builder.sh dev-js     # show components for build dev-js

# build a gen dev env
./wsl-builder.sh system update,qol
./wsl-builder.sh dev essentials,qol,vscode
./wsl-builder.sh dev-js node,yarn,nvm,essentials
change-hostname my-dev-box

# build a python environment for AI coding
./wsl-builder.sh system update,qol
./wsl-builder.sh dev essentials,qol,cursor
./wsl-builder.sh dev-python conda
./wsl-builder.sh ai cuda132
change-hostname python-ai
```
* Each build is very simple, containing only a few related components intended to deliver a single purpose.
* Pick and choosem use multiple runs of the build tool to stack components / packages / features from different builds as you need.
* Build history is kept in `~/.wsl-build.info`

## Build List

| Build | Packages, Frameworks, Tools & Extras | Additional Conf |
| ----- | -------------------------------------- | --------------- |
| [ai](builds/ai/) | **cuda124**: CUDA 12.4<br>**cuda132**: CUDA 13.2<br>**ollama**<br>**cuda-wsl-lib-symlinks**: fix 'not symlinks' issue | **ollama**: `OLLAMA_MODELS` |
| [ai-resources](builds/ai-resources/) | **sg3**: stylegan3, pkl cache, pytorch cache<br>**lsd**: lucid-sonic-dreams<br>**spleeter**<br>**rudalle** | **sg3**, **lsd**, **spleeter**,<br/>**rudalle**:<br/>`AI_RESOURCES_PROJECT_DIR`<br/>**sg3**: `STYLEGAN3_PKL_CACHE`,<br/>`STYLEGAN3_PYTORCH_CACHE` |
| [db](builds/db/) | **mysql-client**<br>**mysql-server**<br>**postgres-client**<br>**postgres-server** | |
| [dev](builds/dev/) | **essentials**: curl, wget, git, vim, nano, jq, yq<br>**vscode**<br>**qol**: code home symlink<br>**cursor**: tree, `code` alias | **essentials**: `GIT_*`,<br/>`GIT_CREDENTIALS_HELPER`<br/>**qol**: `CODE_HOME_SYMLINK`,<br/>`CODE_HOME_TARGET` |
| [dev-bash](builds/dev-bash/) | **shellcheck**<br>**bats** | |
| [dev-js](builds/dev-js/) | **node**: Node.js, npm<br>**nvm**<br>**yarn**<br>**react**: create-vite, react-devtools<br>**nextjs**<br>**angular**<br>**vue**: create-vue<br>**express**<br>**essentials**: TypeScript, ESLint, Prettier, PM2, nodemon, serve | |
| [dev-python](builds/dev-python/) | **python3**<br>**conda**: Anaconda | |
| [dev-ssg](builds/dev-ssg/) | **hugo**<br>**jekyll**: Bundler, Ruby deps | |
| [devops](builds/devops/) | **docker**<br>**docker-desktop**<br>**terraform**<br>**packer**<br>**kubectl**<br>**k9s** | |
| [devops-aws](builds/devops-aws/) | **awscli**<br>**qol**: `aws-profile` alias | |
| [system](builds/system/) | **update**: apt update + upgrade<br>**essentials**: htop, rsync<br>**x11**: Windows native GUI<br>**smb**: smbclient, cifs-utils<br>**nfs**: nfs-common<br>**systemd**<br>**wslu**: wslview, wslsys<br>**qol**: safety aliases, `change-hostname`, default user<br>**apt-mirror-switch**: Canonical vs Uni of Kent apt mirror helper<br>**fstab**: WSL mount config | **qol**: `WIN_HOME_SYMLINK`,<br/>`WIN_HOME_TARGET` |


## Enabling + Configuring WSL2 on the Windows Host
* Open PowerShell as an Administrator
* `wsl --install`

### Git Integration
* Install git on the Windows machine, ensure you select the option to use unix line endings.
  * We are coding in linux, not Windows.
* To use the credentials from your Windows host on the WSL instance, see the [wsl-builds.conf](#wsl-builds) section.

### Cursor Integration
* Install Cursor on the Windows machine, open it and launch it.
* Press CTRL + SHIFT + P to bring up the command palette
* Search for and run: `Shell Command: Install 'cursor' command`
* You can now type `cursor` on the WSL instance to launch the current directory in a Cursor editor, running in Windows, with a remote connection to your WSL instance — sweet.

### VSCode Integration
* Install VSCode on the Windows machine, select Additional Tasks, be sure to check the "Add to PATH" option.
* Now you can simply type `code .` on the WSL instance to open the editor in windows.
* The first time this command is run, it will install the package on the WSL instance.
* Install VSCode WSL extension
  * https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack

### CUDA Integration
* Install an NVIDIA **Windows** driver with WSL CUDA support
* Use `./wsl-builder.sh ai cuda132` to install the CUDA toolkit (or `cuda124`) on the WSL instance. **Do not** install Linux GPU drivers in WSL.
* For more info: [CUDA on WSL User Guide](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)
* If you see `libcuda.so.1 is not a symbolic link`, run the [ai **cuda-wsl-lib-symlinks** component](builds/ai/) to fix it.

### Resource Allocation
* Default memory is 50% of the Windows host memory: https://learn.microsoft.com/en-us/windows/wsl/wsl-config
* For ai work in particular you may find it useful to increase default memory, swap space and enable gradual memory reclaim, eg...

```
[wsl2]
memory=24GB
swap=16GB
networkingMode=mirrored       # Bridge Windows and WSL2 networking (use this carefully)

[experimental]
autoMemoryReclaim=gradual
autoMemoryReclaim=dropcache   # better for ai workloads
sparseVhd=true                # reduces disk space usage with neglibible i/o overhead
```

---

## WSL2 Distro Manager
Useful GUI for managing instances: https://github.com/bostrot/wsl2-distro-manager

---

## WSL Command Reference

### Useful WSL commands
```
wsl -l -v
wsl --list --online
wsl --install Ubuntu-22.04
wsl --export Ubuntu E:\WSL\builds\build-name
wsl --unregister Ubuntu-22.04
wsl --import my-project-name E:\WSL\instances\project-name D:\WSL\builds\build-name
wsl --shutdown
wsl --distribution my-project-name
```

### Manual Snapshots
* Shutdown the instance, export it to your build dir and kill it;
  * `wsl --shutdown`
  * `wsl --export Ubuntu-22.04 E:\WSL\builds\system-base`
  * `wsl --unregister Ubuntu-22.04`
* Your buttery biscuit base is ready to create new instances from :)
  * `wsl --import my-new-project E:\WSL\instances\my-new-project E:\WSL\builds\biscuit`