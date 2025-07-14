# WSL Builds
Buttery biscuit base builds for WSL2... because native Linux development on Windows facilitates some very easy & comfortable workflows :) 

This project contains clean, simple builds that use Windows host native implementations of core components for maximum performance & flexibility;

* VSCode, Cursor
* Git
* Nvidia CUDA
* GUI Apps

The builder provides an easy way to stack components to create different WSL builds for different purposes.

* Simple installations, often featuring quality of life configurations and helpers
* Caching of large downloads on the Windows host - so you don't have to re-downlaod install packages for rebuilds.
* Other build specific cache directories on the Windows host for convenience (eg: AI build .pkl cache)

## Install
After provisioning a basic WSL instance, clone this project repo on it...
```
git clone https://github.com/SpoddyCoder/wsl-builds.git
```
* Create your config file from the template and update it with your own details / paths
```
cd wsl-builds
cp wsl-builds.conf.example wsl-builds.conf
nano wsl-builds.conf
```
Tip: you can easily automate this using [WSL2-Distro-Manager snippets](./README.md#wsl2-distro-manager)

## Build List
* [biscuit](biscuit/)
  * system upgrade
  * quality of life
  * x11 apps
* [dev](dev/)
  * essentials
  * quality of life
  * vscode
  * cursor
* [dev-python](dev-python/)
  * python3
  * anaconda
* [devops](devops/)
  * terraform
  * kubectl
* [devops-aws](devops-aws/)
  * aws cli v2
  * quality of life
* [system](system/)
  * essentials
  * smb client tools
  * nfs client tools
  * fstab mounting config
  * systemd
  * wslu
* [ai](ai/)
  * cuda 12.4
* [ai-resources](ai-resources/)
  * stylegan3
  * lucid-sonic-dreams
  * spleeter
  * rudalle

## Building
```
./build.sh <build-dir> [buildcomponents,...] [additionalargs]... [--force]
```
* `build-dir` valid build directory, containing `conf.sh` & `install.sh`
* `buildcomponents,...` comma seperated list of build components (packages to install etc.), varies per build.
* `additionalargs...` additional arguments required for some builds
* `--force` by default the build will not run if any of the requested build components have already been installed. Use this to force the build.
* The bullder can be run as your current user, but some components will run commands that require escalated priveleges using `sudo`
* It is not designed to be used non-interactively - some installs may need user input / confirmation.

### Assembling and Stacking Builds
* Build history is kept in `~/.wsl-build.info`
* Each build is very simple, containing only a few related components intended to deliver a single purpose.
* Pick and choose - use multiple runs of the build tool to stack components / packages / features from different builds as you need.
```bash
# gen dev env
./build.sh biscuit update,qol
./build.sh dev essentials,qol,vscode,python3
change-hostname my-dev-box

# Python environment for AI coding
./build.sh biscuit update,qol
./build.sh dev essentials,qol,cursor
./build dev-python conda
./build.sh ai cuda124
change-hostname python-ai

# ai-resources requires ai (specified in its docs)
./build.sh ai cuda124
./build.sh ai-resources sg3,lsd
change-hostname stylegan-ai-projects
```

---

## Enabling + Configuring WSL2 on the Windows Host
* Open PowerShell as an Administrator
* `wsl --install`

### Git Integration
* Install git on the Windows machine, ensure you select the option to use unix line endings.
  * We are coding in linux, not Windows.
* To use the credentials from your Windows host on the WSL instance, see below.

### Cursor Integration
* Luanch cursor on Windows machine 
* Press CTRL + SHIFT + P to bring up the command pallete
* Search for and run: `Shell Command: Install 'cursor' command`
* You can now type `cursor` on the WSL instance to launch the current directory in a cursor editor, running in Windows, with a remote connection to WSL intance - sweet.

### VSCode Integration
* Install VSCode on the windows machine, select Additional Tasks, be sure to check the "Add to PATH" option.
* Now you can simply type `code .` on the WSL instance to open the editor in windows.
* The first time this command is run, will install the package on the WSL instance.
* Install VSCode WSL extension
  * https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack

### CUDA Integration
* Apply fix to Windows for Nvidia CUDA issues
  * [https://github.com/microsoft/WSL/issues/5663](https://github.com/microsoft/WSL/issues/5663#issuecomment-1068499676)
* Run a command line shell as Administrator, type `cmd` to get a non-powershell command line
* `cd C:\Windows\System32\lxss\lib && del libcuda.so && del libcuda.so.1 && mklink libcuda.so libcuda.so.1.1 && mklink libcuda.so.1 libcuda.so.1.1`

### Resource Allocation
* Default memory is 50% of windows memory.
* https://learn.microsoft.com/en-us/windows/wsl/wsl-config
* Careful with CLRF line endings when editing this file
* Do it on a WSL instance, eg: `nano /mnt/c/Users/me/.wslconfig`
* For ai work in particular you may find it useful to increase default memory & swap space, eg...

```
[wsl2]
memory=24GB
swap=8GB
```

---

## WSL2 Distro Manager
Useful GUI for managing instances: https://github.com/bostrot/wsl2-distro-manager

### Add WSL-Builds Snippets
* This is a one time action - you will use these two snippets on all WSL-Builds you create.
* Copy + paste each snippet, updating names / paths to suit you. Save it with the specified name.

#### `git-config`
```bash
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
git config --global user.email "my@email.com"
git config --global user.name "me"
git config --global pull.rebase false
```

#### `wsl-builds`
```bash
git clone https://github.com/SpoddyCoder/wsl-builds.git ~/wsl-builds
echo 'CACHE_DIR=/mnt/c/WSL/cache' >> ~/wsl-builds/wsl-builds.conf
echo 'WIN_HOME_SYMLINK=/home/me/c-home' >> ~/wsl-builds/wsl-builds.conf
echo 'WIN_HOME_TARGET=/mnt/c/Users/me' >> ~/wsl-builds/wsl-builds.conf
echo 'CODE_HOME_SYMLINK=/home/me/e-apps' >> ~/wsl-builds/wsl-builds.conf
echo 'CODE_HOME_TARGET=/mnt/e/Apps' >> ~/wsl-builds/wsl-builds.conf
```

### Build Using WSL2 Distro Manager
Using the snippets, this becomes so easy...
* Add Instance
  * Name: `biscuit`
  * Distro: `Ubuntu 22.04`
  * Username: `yourusername`
* Run the `git-config` snippet
* Run the `wsl-builds` snippet
* Finally, open a terminal on the WSL instance and use the builder to cook your buttery biscuit base;
* `./build.sh biscuit update,qol`

### Snapshots
Useful if you are expecting to need to restore to a build point frequently and don't want to go through installation steps every time...
* Make a template from the build and kill the instance.
* It's now ready to use as a base for future instances.

---

## Manually Creating, Exporting and Importing WSL Instances
The pain point here is needing to add config everytime you build a new instance. That's what makes snippets so great.

### Manual Build
* Create a new WSL instance;
  * `wsl --install Ubuntu-22.04`
  * Complete the basic install steps
* On the WSL instance, setup git for WSL;
  * `git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"`
  * `git config --global user.email "my@email.com"`
  * `git config --global user.name "me"`
  * `git config --global pull.rebase false`
  * https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-git
* Clone this repo on the instance and add config file (update names / paths to suit);
  * See the `wsl-builds` snippet in the WSL2 Distro Manager instructions
* Add the buttery base;
  * `./build.sh biscuit update,qol`

### Manual Snapshots
* Shutdown the instance, export it to your build dir and kill it;
  * `wsl --shutdown`
  * `wsl --export Ubuntu-22.04 E:\WSL\builds\biscuit`
  * `wsl --unregister Ubuntu-22.04`
* Your buttery biscuit base is ready to create new instances from :)
  * `wsl --import my-new-project E:\WSL\instances\my-new-project E:\WSL\builds\biscuit`

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
