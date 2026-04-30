# Bats regressions (`bats-core`)

[**`bats`**](https://github.com/bats-core/bats-core) suites for **`./build.sh`** live here and run **only inside Docker** (fast; keeps the same blast-radius story as installs). See **[`docs/testing-requirements.md`](../../docs/testing-requirements.md)**.

[**`build_test_fixture_harness.bats`**](build_test_fixture_harness.bats) covers **CLI paths that exit before `install.sh`** (allowlisted in **`allowed-build-invocations.sh`**) and the noop **`test-fixture`** dispatch harness (**`--force`**, comma lists, invalid component).

**Recommended / CI-parity:**

```bash
docker build -t wsl-builds-test .
docker run --rm -v "$(pwd):/repo" -w /repo \
  wsl-builds-test \
  bash ./test/container-isolated/run-bats-in-container.sh
```

Do **not** run bare `bats test/container-isolated/` on your host unless you replicate the helper’s **`wsl-builds.conf`** setup from [`wsl-builds.conf.container.example`](../../wsl-builds.conf.container.example)—use the Docker command instead.
