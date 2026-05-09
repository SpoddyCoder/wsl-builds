# test-fixture

**Automated testing only.** 

* This build exists to exercise `./wsl-builder.sh` → `install.sh` → [`src/builder/install-dispatch.sh`](../../src/builder/install-dispatch.sh)
* noop components
* `getfile-harness` component that covers [`getFile` / `cleanupGetFiles`](../../src/builder/install-helpers.sh)
* `getfile-stale-harness`stale-cache prompt + refresh;
  * set `WSL_BUILDS_GETFILE_STALE_EXPECT` to `cache` or `refresh` and use harness `wsl-builds.conf`
  * `WARN_IF_CACHED_FILE_OLDER_THAN` and `file-edit-harness`, which exercises [`ensureShellRcRegion`](../../src/builder/shell-rc.sh) and [`ensureWslConfIniLine`](../../src/builder/wsl-conf.sh) in Docker.
* Do not rely on it for real environments.
* See **[`test/README.md`](../../test/README.md)** for more info.
