# `security`

WSL instance hardening for sandbox-style isolation from the Windows host.

## Requires

* `Ubuntu 22.04` or greater

## Build Components

### `harden-sandbox`

* Sets `/etc/wsl.conf` `[automount]` `enabled = false`, `mountFsTab = false` (no automatic DrvFs mounts under `/mnt`, no fstab processing on start)
* Sets `/etc/wsl.conf` `[interop]` `enabled = false`, `appendWindowsPath = false` (no launching Windows processes from WSL; Windows executables removed from PATH)
* Prompts to remove symlinks directly under `$HOME` whose target is under `/mnt/` (host paths)
* Optional host → `~/.wsl-builds.conf` migration: if a readable host config exists (`WSL_BUILDS_CONF` or the default `%USERProfile%\.wsl-builds\wsl-builds.conf` path), prompts to copy it to `~/.wsl-builds.conf` and remove the managed `WSL_BUILDS_CONF` export from shell rc (default Yes; EOF/non-interactive accepts the default)
* Warns when global `credential.helper` or `GIT_CREDENTIALS_HELPER` in host config points at a Windows path (for example Git Credential Manager under `/mnt/c`); those helpers stop working after restart—re-authenticate on Linux (SSH keys, `gh auth login`, or a Linux credential helper)
* After install, lists any non-comment lines in `~/.wsl-builds.conf` that still reference `/mnt/`; review the file and remove or relocate those settings into the distro before relying on them post-restart

Restart required: WSL reads `/etc/wsl.conf` when the distro starts. DrvFs mounts, interop, and Windows on `PATH` stay as they were until you fully stop this instance (all terminals and IDE remote sessions), then start it again. From PowerShell you can check `wsl --list --running` or run `wsl --shutdown`.

Stack ordering: run after builds that create host symlinks (for example `system,symlinks`) if you want removal prompts in the same session. If `symlinks` runs later, links may be recreated. Run after `dev,essentials` (or any build that sets a host Git credential helper) if you want the pre-harden warning in the same session.

`wsl.conf` conflicts: another component may already set the same key (for example `system,fstab` adds `mountFsTab = true`). This component appends lines; WSL uses the last value in the file. Run `harden-sandbox` last when that is intentional.

```bash
./wsl-builder.sh security harden-sandbox
```

## Limits of sandboxing

* Networking between the WSL instance and the Windows host remains enabled. This component does not isolate the network namespace.
* Further hardening on the Windows host is optional via `%UserProfile%\.wslconfig` ([Advanced settings](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)):
  * `[wsl2]` resource limits: `memory`, `processors`, `swap`
  * `[experimental]` `guiApplications=false` (disables WSLg)
  * WSL vEthernet firewall rules are configured on Windows, not inside the distro

See also the repo root README section on Windows host resource allocation for `.wslconfig` examples.

## Build Arguments

* No additional arguments for this build
