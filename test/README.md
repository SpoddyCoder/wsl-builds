# Tests

Host-side:

- [`lint.sh`](lint.sh) — ShellCheck and `bash -n` (same as [.github/workflows/lint.yml](../.github/workflows/lint.yml)).
- [`run-tests.sh`](run-tests.sh) — lint, `docker build -f test/docker/Dockerfile`, `docker run` the test image (see [**Testing** in `CONTRIBUTING.md`](../CONTRIBUTING.md)).

Docker test image and Bats harness (do **not** run [`docker/run-bats.sh`](docker/run-bats.sh) on the host; it overwrites repo-root `wsl-builds.conf`):

- [`docker/`](docker/) — [`Dockerfile`](docker/Dockerfile), [`Dockerfile.dockerignore`](docker/Dockerfile.dockerignore), [`run-bats.sh`](docker/run-bats.sh), [`*.bats`](docker/build_test_fixture_harness.bats), [`wsl-builds.conf.container`](docker/wsl-builds.conf.container).

Use **`./test/run-tests.sh`** from the repo root instead of running Bats manually.
