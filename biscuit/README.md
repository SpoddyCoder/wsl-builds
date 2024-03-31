# `biscuit`
This is our base install, with very little extra added.

* Build Options;
  * `update`
    * Update apt & upgrade the system, recommended first step
  * `qol`
    * Set default user, add symlinks if defined, add bash safety aliases
    * Symlink definitions picked up from your `wsl-builds.conf`, see below
  * `x11`
    * Install the X11-Apps package for native Windows GUI support
  * `vscode`
    * Install the VSCode extensions for native Windows VSCode integration
* Build Arguments
  * No additional arguments for this build
* Requires
  * `Ubuntu 22.04`


## Build Using WSL2 Distro Manager
* Add Instance
  * Name: `biscuit`
  * Distro: `Ubuntu 22.04`
  * Username: `yourusername`
* Save this snippet as `biscuit-config`, update the names / paths to suit you;

```
git clone https://github.com/SpoddyCoder/wsl-builds.git ~/wsl-builds
echo 'CACHE_DIR=/mnt/c/WSL/cache' >> ~/wsl-builds/wsl-builds.conf
echo 'WIN_HOME=/mnt/c/Users/me' >> ~/wsl-builds/wsl-builds.conf
echo 'WIN_HOME_SYMLINK=/home/me/c-home' >> ~/wsl-builds/wsl-builds.conf
echo 'CODE_HOME=/mnt/e/Apps' >> ~/wsl-builds/wsl-builds.conf
echo 'CODE_HOME_SYMLINK=/home/me/e-apps' >> ~/wsl-builds/wsl-builds.conf
```

* Important: you must type the Snippet into the editor manually
  * copy + paste will result in CLRF issues: https://github.com/bostrot/wsl2-distro-manager/issues/237
* Run the snippet on the instance
* Use the builder to build the buttery biscuit base;
  * `./build.sh biscuit x11,vscode`
* Make a template from the build and kill the instance. It's now ready to use as a base for future instances.


## Manual Build
* Create a new WSL instance;
  * `wsl --install Ubuntu-22.04`
  * Complete the basic install steps
* On the instance, setup git for WSL;
  * `git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"`
  * `git config --global user.email "my@email.com"`
  * `git config --global user.name "me"`
  * `git config --global pull.rebase false`
  * https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-git
* Clone this repo on the instance and add config file (update names / paths to suit);
  * See the `biscuit-config` snippet in the WSL2 Distro Manager instructions
* Add the buttery base;
  * `./build.sh biscuit x11,vscode`
* Shutdown the instance, export it to your build dir and kill it;
  * `wsl --shutdown`
  * `wsl --export Ubuntu-22.04 E:\WSL\builds\biscuit`
  * `wsl --unregister Ubuntu-22.04`
* Your buttery biscuit base is ready to create new instances from :)
  * `wsl --import my-new-project E:\WSL\instances\my-new-project E:\WSL\builds\biscuit`
