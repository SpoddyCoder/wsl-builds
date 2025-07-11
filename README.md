# WSL Builds
Buttery biscuit base builds for WSL2. Native Linux development on Windows facilitates some very easy & comfortable workflows :) 

This project contains clean, simple builds that use Windows host native implementations of core components for maximum performance & flexibility;

* GUI Apps
* Git
* VSCode
* Nvidia CUDA


## Build List
* [biscuit](biscuit/)
  * system upgrade
  * qol bits
  * x11 apps
  * vscode
  * cursor editor support
* [dev-basics](dev-basics/)
  * essential development tools
  * python3 development environment
* [ai-basics](ai-basics/)
  * conda
  * cuda 12.4
* [ai-resources](ai-resources/)
  * stylegan3
  * lucid-sonic-dreams
  * spleeter
  * rudalle


## Install
```
git clone https://github.com/SpoddyCoder/wsl-builds.git ~/wsl-builds
cd ~/wsl-builds
cp wsl-builds.conf.example wsl-builds.conf
# update the conf with your own details / paths
nano wsl-builds.conf
```


## Building Instances
```
./build.sh <build-dir> [buildoptions,...] [additionalargs]... [--force]
```
* `build-dir` valid build directory, containing `conf.sh` & `install.sh`
* `buildoptions,...` comma seperated list of build options (packages to install etc.), varies per build.
* `additionalargs...` additional arguments required for some builds
* `--force` by default the installer will not run if any version of the build has already been installed. Use this to force the install. It is generally better / safer to do clean installs, but this can be useful.

Examples:
```
./build.sh biscuit upgrade,qol
./build.sh biscuit x11,vscode --force
./build.sh dev-basics essentials,python3
./build.sh ai-basics conda,cuda124
```

### Assembling and Stacking Builds
* Each build is very simple, containing only a few related components intended to deliver a single purpose.
* Use the build tool to add components / packages / features from different builds as you need.
* Eg, a general development environment...
```
./build.sh biscuit vscode,cursor
./build.sh dev-basics essentials,python3
```
* Eg, a Python environemnt for AI coding...
```
./build.sh biscuit vscode
./build.sh ai-basics conda
```
* Eg, `ai-resources` builds upon `ai-basics`...
```
./build.sh biscuit vscode
./build.sh ai-basics conda,cuda124
./build.sh ai-resources sg3
```
* Build history is kept in `~/.wsl-build.info`


## Enabling + Configuring WSL2
* Open PowerShell as an Administrator
  * `wsl --install`
* Apply fix to Windows for Nvidia CUDA issues;
  * Run a command line shell as Administrator, type `cmd` to get a non-powershell command line
  * `cd C:\Windows\System32\lxss\lib && del libcuda.so && del libcuda.so.1 && mklink libcuda.so libcuda.so.1.1 && mklink libcuda.so.1 libcuda.so.1.1`
  * [https://github.com/microsoft/WSL/issues/5663](https://github.com/microsoft/WSL/issues/5663#issuecomment-1068499676)

### Git Integration
* Install git on the Windows machine, ensure you select the option to use unix line endings.
  * We are coding in linux, not Windows.
* To use the credentials from your Windows host on the WSL instance, run the following;
  * `git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"`
    * Change this if not installed in standard location 
  * `git config --global user.email "me@my.com"`
  * `git config --global user.name "Me"`
  * `git config --global pull.rebase false`  (adjust to your prefernece)
  * Hint: save this as a snippet in WSL2 Distro Manager to make it easy to apply to newly built instances.

### VSCode Integration
* Install VSCode on the windows machine, select Additional Tasks, be sure to check the "Add to PATH" option.
  * Now you can simply type `code .` on the wsl instance to open the editor in windows - nice!
  * The first time this command is run, will install the package on the WSL instance.
* Install VSCode WSL extension
  * https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack

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


## Creating, Exporting and Importing WSL Instances
```
wsl -l -v
wsl --list --online
wsl --install Ubuntu-22.04
wsl --export Ubuntu E:\WSL\builds\build-name
wsl --unregister Ubuntu-22.04
wsl --import project-name E:\WSL\instances\project-name D:\WSL\builds\build-name
wsl --shutdown
wsl --distribution project-name
```

### WSL2 Distro Manager
* Useful GUI for managing instances;
  * https://github.com/bostrot/wsl2-distro-manager
