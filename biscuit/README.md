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
  * `cursor`
    * Install basic packages that Cursor editor likes to use (includes `tree`)
* Build Arguments
  * No additional arguments for this build
* Requires
  * `Ubuntu 22.04`

