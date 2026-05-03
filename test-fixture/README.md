# test-fixture

**Automated testing only.** This build exists to exercise `./build.sh` → `install.sh` → [`src/install-dispatch.sh`](../src/install-dispatch.sh) with noop components, a **`getfile-harness`** component that covers [`getFile` / `cleanupGetFiles`](../src/install-helpers.sh), and **`file-edit-harness`**, which exercises [`ensureShellRcRegion`](../src/shell-rc.sh) and [`ensureWslConfIniLine`](../src/wsl-conf.sh) in Docker. Do not rely on it for real environments.

See [test/README.md](../test/README.md).
