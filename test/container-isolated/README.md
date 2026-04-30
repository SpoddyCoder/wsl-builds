# Bats regressions (`bats-core`)

[**`bats`**](https://github.com/bats-core/bats-core) suites for **`./build.sh`** live here and run **only inside Docker** (image embeds the repo at **`docker build`** time; no host bind mount). Maintainer notes: **Testing** in [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

[**`build_test_fixture_harness.bats`**](build_test_fixture_harness.bats) covers **CLI paths that exit before `install.sh`** (allowlisted in **`allowed-build-invocations.sh`**) and the noop **`test-fixture`** dispatch harness (**`--force`**, comma lists, invalid component).

**Recommended (lint + bats in Docker):** from repo root:

```bash
./test/run-tests.sh
```

Do **not** run bare `bats test/container-isolated/` on your host unless you replicate the helper’s **`wsl-builds.conf`** setup from [`wsl-builds.conf.container`](wsl-builds.conf.container)—run **`./test/run-tests.sh`** from the repo root instead.
