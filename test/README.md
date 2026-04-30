# Tests

- [`lint.sh`](lint.sh) — repo-wide ShellCheck and `bash -n` (same entrypoint as [.github/workflows/lint.yml](../.github/workflows/lint.yml)).
- [`run-tests.sh`](run-tests.sh) — runs lint, builds the bats image, runs suites in Docker (details in [**Testing** in `CONTRIBUTING.md`](../CONTRIBUTING.md)).
- [`container-isolated/`](container-isolated/) — **`bats-core`** harness for **`build.sh`**.
