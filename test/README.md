# Testing

Automated checks cover ShellCheck/`bash -n` and Bats tests running in an isolated Docker container for safety.

## How to run

* [`./lint.sh`](lint.sh) - **Lint only** - ShellCheck + `bash -n`
* [`./run-tests.sh`](run-tests.sh) - **Lint + Bats** - builds the image from [`docker/Dockerfile`](docker/Dockerfile), then runs the Bats tests in the container.
* CI also runs these via [.github/workflows/lint.yml](../.github/workflows/lint.yml) and [.github/workflows/test.yml](../.github/workflows/test.yml).

```bash
./test/run-tests.sh
```

[`bats-core`](https://github.com/bats-core/bats-core) tests in [`docker/*.bats`](docker/) drive the [`test-fixture`](../test-fixture/) build. The image **copies the repo at build time** (no host bind mount) so the tests run in an isolated environment.

* **Do not** run [`docker/run-bats.sh`](docker/run-bats.sh) on the host — it overwrites repo-root **`wsl-builds.conf`**.
* **Docker harness files:** [`docker/`](docker/) - contains the Docker image and all the files necesary to run the Bats tests in an isolated container.

Before changing `build.sh`, `src/install-dispatch.sh`, shared helpers under `src/`, or Bats tests, skim this doc and run **`./test/run-tests.sh`** when behaviour may regress.

## Bats catalog (`docker/build-test-fixture-harness.bats`)

Each row is one `@test`. The **`#`** column matches Bats TAP numbering (`ok N …`) when tests run in file order (default). Tests use an isolated `$HOME` and harness `wsl-builds.conf`.

| # | Test | What it checks |
| -: | ---- | ---------------- |
| 1 | `build.sh with no arguments exits nonzero and prints usage` | No args → failure, usage line, “available build directories” line. |
| 2 | `unknown build directory exits nonzero` | Fake build dir → error and nonzero exit. |
| 3 | `single-arg test-fixture lists components without running install pipeline` | Only `test-fixture` → usage + component list, no successful install. |
| 4 | `noop component noop-hyphen runs full harness and succeeds` | Full path for `noop-hyphen` → success, banner, `installed!`. |
| 5 | `comma-separated noop-hyphen (hyphen token) and noop (plain token) dispatch` | CSV `noop,noop-hyphen` runs both tokens and succeeds. |
| 6 | `invalid component for test-fixture fails` | Unknown component → invalid component error. |
| 7 | `--force with noop-hyphen succeeds` | `--force` accepted after component list. |
| 8 | `successful install writes ~/.wsl-build.info with OS header and component line` | First-line OS-style header (has whitespace), ≥2 lines, exact component record line. |
| 9 | `comma-separated installs append one record line per component` | Two components → two distinct lines in build.info, each once. |
| 10 | `second install without --force skips and does not duplicate build.info lines` | Re-run same component → skip warnings, “No changes made”, single record line. |
| 11 | `--force reinstall appends another identical component line to build.info` | Second run with `--force` → duplicate identical component line (count 2). |
| 12 | `touch-marker writes sentinel file and records success in build.info` | Component touches marker under `$HOME` and logs success line. |
| 13 | `usage output lists test-fixture among available build directories` | Usage listing includes `test-fixture` under available dirs. |
| 14 | `too many arguments exits nonzero` | Extra positional arg after component → “too many arguments”. |
| 15 | `comma-separated valid then invalid component fails` | `noop,<bad>` fails validation after seeing valid prefix. |
| 16 | `--force alone without component fails validation` | `test-fixture --force` invalid — `$2` must be a component. |
| 17 | `empty component argument fails validation` | Empty second arg treated as invalid component. |
| 18 | `component match is case-insensitive; build.info keeps canonical token` | `NOOP-HYPHEN` installs; record uses lowercase hyphen form from metadata. |
| 19 | `failed validation leaves ~/.wsl-build.info absent` | Unknown build dir then invalid component — still no build.info under fake `$HOME`. |
| 20 | `multiple installs reuse single OS header line in build.info` | Sequential `noop` then `touch-marker` → two component lines, one non-component line (OS header). |
