# Testing

Automated checks cover ShellCheck/`bash -n` and Bats tests running in an isolated Docker container for safety.

## How to run

* [`./lint.sh`](lint.sh) - **Lint only** - ShellCheck + `bash -n`
* [`./run-tests.sh`](run-tests.sh) - **Lint + Bats** - builds the image from [`docker/Dockerfile`](docker/Dockerfile), then runs the Bats tests in the container.
* CI also runs these via [.github/workflows/lint.yml](../.github/workflows/lint.yml) and [.github/workflows/test.yml](../.github/workflows/test.yml).

```bash
./test/run-tests.sh
```

[`bats-core`](https://github.com/bats-core/bats-core) tests in [`docker/*.bats`](docker/) cover **build-fixture** regressions and **wizard** behaviour for `./wsl-builds-conf.sh`. The image **copies the repo at build time** (no host bind mount) so the tests run in an isolated environment.

* **Do not** run [`docker/run-bats.sh`](docker/run-bats.sh) on the host — it overwrites repo-root **`wsl-builds.conf`**.
* **Docker harness files:** [`docker/`](docker/) - contains the Docker image and all the files necesary to run the Bats tests in an isolated container.

Before changing `build.sh`, `src/install-dispatch.sh`, shared helpers under `src/`, `wsl-builds-conf.sh`, or Bats tests, skim this doc and run **`./test/run-tests.sh`** when behaviour may regress.

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
| 21 | `WSL_BUILDS_CONF set to readable file is sourced and path is printed` | `WSL_BUILDS_CONF` points at a copy of the harness file → build succeeds; output names that path. |
| 22 | `WSL_BUILDS_CONF set but not readable exits nonzero` | Missing path → nonzero exit; output reports unreadable `WSL_BUILDS_CONF`. |

## Wizard catalog (`docker/wsl-builds-conf-wizard.bats`)

Wizard tests snapshot repo-root **`wsl-builds.conf`** each test and restore it in `teardown` so the build-fixture harness file stays valid for other suites in the same `bats` run. Each row is one `@test`. TAP numbers are **23–37** when [`run-bats.sh`](docker/run-bats.sh) runs files in lexical order (`build-test-fixture-harness.bats` first).

| # | Test | What it checks |
| -: | ---- | -------------- |
| W1 | `--help` exits 0 and prints usage | Status 0; output contains `Usage:`. |
| W2 | Unknown option fails | Nonzero; `Unknown option` in output. |
| W3 | `--noninteractive` creates repo `wsl-builds.conf` from example | Linux-only env (no host default): file created; output mentions example. |
| W4 | `--noninteractive` when repo conf exists is no-op | `already exists` message; file checksum unchanged. |
| W5 | Non-TTY stdin auto-forces noninteractive | `./wsl-builds-conf.sh </dev/null` copies example when missing (same class as W3). |
| W6 | `--defaults` alias | Same outcome as W3. |
| W7 | No managed `~/.bashrc` block without host default | After noninteractive copy-example path, no `wsl-builds (managed)` markers in fake `$HOME`. |
| W8 | `removeManagedBashrcBlock` with no `~/.bashrc` | No-op; no error (sourced script). |
| W9 | `removeManagedBashrcBlock` strips managed region only | Outside lines survive; inner lines removed. |
| W10 | `removeManagedBashrcBlock` with no markers | File byte-for-byte unchanged. |
| W11 | `writeManagedBashrcBlock` replace / idempotent | Two calls → one block; final `WSL_BUILDS_CONF` path is the second. |
| W12 | Path quoting in managed block | Path with spaces and `$`; `source ~/.bashrc` exports correct value. |
| W13 | `normalizeHostConfPath` absolute readable | Returns same path. |
| W14 | `normalizeHostConfPath` empty input | Fails. |
| W15 | `normalizeHostConfPath` non-absolute | Fails without `wslpath` success (Linux image). |
| W16 | Pre-seeded managed `~/.bashrc` block stripped on fall-through | `--noninteractive` removes managed markers, preserves surrounding lines. |
| W17 | Shell hint warns when `WSL_BUILDS_CONF` is set in env | `WSL_BUILDS_CONF=/path … --noninteractive` → `WARN: WSL_BUILDS_CONF still set`. |
| W18 | Shell hint silent when `WSL_BUILDS_CONF` is unset | `--noninteractive` with no env var → no `still set` line. |
