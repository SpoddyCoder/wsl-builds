# Testing

Automated checks cover ShellCheck/`bash -n` and Docker-based Bats regressions against [`build.sh`](../build.sh) and the shared install path ([`src/install-dispatch.sh`](../src/install-dispatch.sh)).

## How to run

* **Lint only (ShellCheck + `bash -n`):** [`./lint.sh`](lint.sh) — same checks as [.github/workflows/lint.yml](../.github/workflows/lint.yml). Contributor setup for ShellCheck lives under **Linting** in [`CONTRIBUTING.md`](../CONTRIBUTING.md).
* **Lint + Docker + Bats:** [`./run-tests.sh`](run-tests.sh) from the **repo root** runs lint, builds the image from [`docker/Dockerfile`](docker/Dockerfile), then runs the container (one command). CI also runs these via [.github/workflows/lint.yml](../.github/workflows/lint.yml) and [.github/workflows/test.yml](../.github/workflows/test.yml).

```bash
./test/run-tests.sh
```

[`bats-core`](https://github.com/bats-core/bats-core) tests in [`docker/*.bats`](docker/) drive the noop [`test-fixture`](../test-fixture/) build. The image **copies the repo at build time** (no host bind mount).

* **Do not** run [`docker/run-bats.sh`](docker/run-bats.sh) on the host — it overwrites repo-root **`wsl-builds.conf`**.
* **Docker harness files:** [`docker/Dockerfile`](docker/Dockerfile), [`docker/Dockerfile.dockerignore`](docker/Dockerfile.dockerignore), [`docker/run-bats.sh`](docker/run-bats.sh), [`docker/build-test-fixture-harness.bats`](docker/build-test-fixture-harness.bats), [`docker/wsl-builds.conf`](docker/wsl-builds.conf).

Before changing `build.sh`, `src/install-dispatch.sh`, shared helpers under `src/`, or Bats tests, skim this doc and run **`./test/run-tests.sh`** when behaviour may regress.

## Bats catalog (`docker/build-test-fixture-harness.bats`)

Each row is one `@test` (order matches the file). Tests use an isolated `$HOME` and harness `wsl-builds.conf`.

| Test | What it checks |
| ---- | ---------------- |
| `build.sh with no arguments exits nonzero and prints usage` | No args → failure, usage line, “available build directories” line. |
| `unknown build directory exits nonzero` | Fake build dir → error and nonzero exit. |
| `single-arg test-fixture lists components without running install pipeline` | Only `test-fixture` → usage + component list, no successful install. |
| `noop component noop-hyphen runs full harness and succeeds` | Full path for `noop-hyphen` → success, banner, `installed!`. |
| `comma-separated noop-hyphen (hyphen token) and noop (plain token) dispatch` | CSV `noop,noop-hyphen` runs both tokens and succeeds. |
| `invalid component for test-fixture fails` | Unknown component → invalid component error. |
| `--force with noop-hyphen succeeds` | `--force` accepted after component list. |
| `successful install writes ~/.wsl-build.info with OS header and component line` | First-line OS-style header (has whitespace), ≥2 lines, exact component record line. |
| `comma-separated installs append one record line per component` | Two components → two distinct lines in build.info, each once. |
| `second install without --force skips and does not duplicate build.info lines` | Re-run same component → skip warnings, “No changes made”, single record line. |
| `--force reinstall appends another identical component line to build.info` | Second run with `--force` → duplicate identical component line (count 2). |
| `touch-marker writes sentinel file and records success in build.info` | Component touches marker under `$HOME` and logs success line. |
| `usage output lists test-fixture among available build directories` | Usage listing includes `test-fixture` under available dirs. |
| `too many arguments exits nonzero` | Extra positional arg after component → “too many arguments”. |
| `comma-separated valid then invalid component fails` | `noop,<bad>` fails validation after seeing valid prefix. |
| `--force alone without component fails validation` | `test-fixture --force` invalid — `$2` must be a component. |
| `empty component argument fails validation` | Empty second arg treated as invalid component. |
| `component match is case-insensitive; build.info keeps canonical token` | `NOOP-HYPHEN` installs; record uses lowercase hyphen form from metadata. |
| `failed validation leaves ~/.wsl-build.info absent` | Unknown build dir then invalid component — still no build.info under fake `$HOME`. |
| `multiple installs reuse single OS header line in build.info` | Sequential `noop` then `touch-marker` → two component lines, one non-component line (OS header). |
