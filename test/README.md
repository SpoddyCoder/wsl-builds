# Testing

Automated checks cover ShellCheck/`bash -n` and Bats tests running in an isolated Docker container for safety.

## How to run

* [`./lint.sh`](lint.sh) - **Lint only** - ShellCheck + `bash -n`
* [`./run-tests.sh`](run-tests.sh) - **Lint + Bats** - builds the image from [`docker/Dockerfile`](docker/Dockerfile), then runs the Bats tests in the container.
* CI also runs these via [.github/workflows/lint.yml](../.github/workflows/lint.yml) and [.github/workflows/test.yml](../.github/workflows/test.yml).

```bash
./test/run-tests.sh
```

[`bats-core`](https://github.com/bats-core/bats-core) tests in [`docker/*.bats`](docker/) cover **build-fixture** regressions, **automated builds review** runners, **review-fixture** scenarios, **wizard** behaviour for `./configure.sh`, and **commands** helpers under `builds/system/`. The image **copies the repo at build time** (no host bind mount). [`docker/run-bats.sh`](docker/run-bats.sh) runs each suite file in its own `bats` process (builder, review, review-fixture, wizard, then commands).

* Builder and review tests use an isolated `$HOME` and copy harness [`docker/wsl-builds.conf`](docker/wsl-builds.conf) to `~/.wsl-builds.conf`. Wizard tests use their own fake `$HOME` only.
* **Docker harness files:** [`docker/`](docker/) - contains the Docker image and all the files necesary to run the Bats tests in an isolated container.

Before changing `./wsl-builder.sh`, `src/builder/install-dispatch.sh`, shared helpers under `src/`, `configure.sh`, or Bats tests, skim this doc and run `./test/run-tests.sh` when behaviour may regress.

## Bats catalog (`docker/builder-tests.bats`)

Each row is one `@test`. The `#` column is the stable **B**… id (same order as TAP `ok N …` in this file). Builder tests use an isolated `$HOME` with harness `~/.wsl-builds.conf` (or `WSL_BUILDS_CONF` where noted).

| # | Test | What it checks |
| -: | ---- | ---------------- |
| B1 | `wsl-builder.sh with no arguments exits nonzero and prints usage` | No args → failure, usage line, “available build directories” line. |
| B2 | `unknown build directory exits nonzero` | Fake build dir → error and nonzero exit. |
| B3 | `single-arg test-fixture lists components without running install pipeline` | Only `test-fixture` → usage + component list, no successful install. |
| B4 | `noop component noop-hyphen runs full harness and succeeds` | Full path for `noop-hyphen` → success, banner, `installed!`. |
| B5 | `comma-separated noop-hyphen (hyphen token) and noop (plain token) dispatch` | CSV `noop,noop-hyphen` runs both tokens and succeeds. |
| B6 | `invalid component for test-fixture fails` | Unknown component → invalid component error. |
| B7 | `--force with noop-hyphen succeeds` | `--force` accepted after component list. |
| B8 | `successful install writes ~/.wsl-build.info with OS header and component line` | First-line OS-style header (has whitespace), ≥2 lines, exact component record line. |
| B9 | `comma-separated installs append one record line per component` | Two components → two distinct lines in build.info, each once. |
| B10 | `second install without --force skips and does not duplicate build.info lines` | Re-run same component → skip warnings, “No changes made”, single record line. |
| B11 | `--force reinstall appends another identical component line to build.info` | Second run with `--force` → duplicate identical component line (count 2). |
| B12 | `touch-marker writes sentinel file and records success in build.info` | Component touches marker under `$HOME` and logs success line. |
| B13 | `usage output lists test-fixture among available build directories` | Usage listing includes `test-fixture` under available dirs. |
| B14 | `too many arguments exits nonzero` | Extra positional arg after component → “too many arguments”. |
| B15 | `comma-separated valid then invalid component fails` | `noop,<bad>` fails validation after seeing valid prefix. |
| B16 | `--force alone without component fails validation` | `test-fixture --force` invalid — `$2` must be a component. |
| B17 | `empty component argument fails validation` | Empty second arg treated as invalid component. |
| B18 | `component match is case-insensitive; build.info keeps canonical token` | `NOOP-HYPHEN` installs; record uses lowercase hyphen form from metadata. |
| B19 | `failed validation leaves ~/.wsl-build.info absent` | Unknown build dir then invalid component — still no build.info under fake `$HOME`. |
| B20 | `multiple installs reuse single OS header line in build.info` | Sequential `noop` then `touch-marker` → two component lines, one non-component line (OS header). |
| B21 | `WSL_BUILDS_CONF set to readable file is sourced and path is printed` | `WSL_BUILDS_CONF` points at a copy of the harness file → build succeeds; output names that path. |
| B22 | `WSL_BUILDS_CONF set but not readable exits nonzero` | Missing path → nonzero exit; output reports unreadable `WSL_BUILDS_CONF`. |
| B29 | `without WSL_BUILDS_CONF builder sources ~/.wsl-builds.conf and prints path` | Default config path is `"Using: ${HOME}/.wsl-builds.conf"` in output. |
| B30 | `missing user config exits nonzero with configure hint` | No `WSL_BUILDS_CONF`, no `~/.wsl-builds.conf` → error names both and `configure.sh`. |
| B31 | `WSL_BUILDS_CONF takes precedence over poisonous ~/.wsl-builds.conf` | Home config contains `exit 1`; env points at harness copy → success; `Using:` is env path. |
| B32 | `empty WSL_BUILDS_CONF falls back to ~/.wsl-builds.conf` | `WSL_BUILDS_CONF=""` → same as default; `Using:` is `"${HOME}/.wsl-builds.conf"`. |
| B33 | `unreadable ~/.wsl-builds.conf exits nonzero with configure hint` | Dangling symlink at `~/.wsl-builds.conf` (`-r` false; avoids root reading mode `000`) → same error class as missing file. |
| B27 | `EXTERNAL_BUILDS_ROOT symlinked build runs install and prints external root` | External builds root via conf; symlinked `test-fixture`; success and banner. |
| B28 | `EXTERNAL_BUILDS_ROOT missing directory exits nonzero` | Bad `EXTERNAL_BUILDS_ROOT` in conf → nonzero; error names missing directory. |
| B23 | `getfile-harness exercises getFile cache hit download cleanupGetFiles and records success` | Runs harness component → success; stdout shows cache-hit and download paths (`wget` via short-lived localhost HTTP server); `~/.wsl-build.info` records `getfile-harness`. |
| B24 | `file-edit-harness updates shell rc and /etc/wsl.conf` | Seeds dummy `/etc/wsl.conf`, runs harness component, asserts `ensureShellRcRegion` block in `~/.bashrc` and `ensureWslConfIniLine` under `[wsl-builds-test]`; restores `/etc/wsl.conf` after. |
| B25 | `getfile-stale-harness stale cache default yes keeps seeded payload` | `WARN_IF_CACHED_FILE_OLDER_THAN=1` in harness conf; aged cache + `printf '\n'` → stale warning and “Using locally cached version”; payload matches seed; `WSL_BUILDS_GETFILE_STALE_EXPECT=cache`. |
| B26 | `getfile-stale-harness stale cache n refreshes from fixture URL` | Same aged cache; `printf 'n\n'` → “Downloading fresh copy”; payload matches HTTP fixture; `WSL_BUILDS_GETFILE_STALE_EXPECT=refresh`. |

## Review catalog (`docker/review-tests.bats`)

Maintainer-oriented overview of the **automated** review (runners, manifests, layout): [`review/README.md`](../review/README.md).

Each row is one `@test`. The `#` column is the stable **R**… id (same order as TAP `ok N …` in this file). Tests use an ephemeral directory under `builds/` with `conf.sh` and a stub `<slug>/audit.sh` (e.g. `review_stub/audit.sh` for token `review-stub`); harness `~/.wsl-builds.conf` is installed like builder tests.

| # | Test | What it checks |
| -: | ---- | ---------------- |
| R1 | `component-review accepts measurement JSON merged with runner fields` | Minimal measurement envelope (**`checks`**, **`required_check_ids`**) → exit 0; path echoed; **`concerns`** on `<slug>/review.result.json`. |
| R2 | `audit stdout carrying policy-view fields fails validation` | Forbidden top-level **`summary`** on audit stdout → nonzero; audit measurement validation. |
| R3 | `audit stdout with forbidden verdict-style field fails validation` | Audit carries **`review_result`** → nonzero; audit measurement validation. |
| R3b | `audit stdout missing checks array fails validation` | Omit **`checks`** → nonzero; audit measurement validation. |
| R4 | `validation failure does not create or overwrite <slug>/review.result.json` | Pre-seeded `review_stub/review.result.json` unchanged when audit output fails validation before merge write. |
| R5 | `successful run overwrites an existing <slug>/review.result.json` | Placeholder cleared; **`concerns`** present on rewritten file; merged runner fields preserved. |
| R5b | `top-level evidence on audit stdout fails validation` | Audit stdout includes legacy top-level **`evidence`** → nonzero; explicit migration guardrail. |
| R6 | `emitConcernsFromChecks sets security and freshness when issues span buckets` | Derivation sets **`concerns.security`** and **`concerns.freshness`** true when **`checks`** carry routed **`issue`** rows in both buckets. |
| R7 | `routes_by_audit_check_id none excludes issue from security/freshness flags` | **`custom_issue_policy`** **`none`** route excludes **`issue`** row from **`security`**/**`freshness`** without **`incomplete`**. |

## Review-fixture catalog (`docker/review-fixture-tests.bats`)

Scenario-based end-to-end coverage that drives `./review/component-review.sh` against the deterministic offline fixture build [`builds/review-fixture/`](../builds/review-fixture/). Each token has a hand-written `<slug>/audit.sh` (no jq, no network) so the runner contract (envelope validation, `concerns` derivation, persisted artefact shape, no-overwrite-on-failure) is exercised reliably. RF tests run after the existing **R**… runner contract guards in [`docker/run-bats.sh`](docker/run-bats.sh) and use the same isolated `$HOME` + harness `~/.wsl-builds.conf` setup as the Review catalog.

Each row is one `@test`. The `#` column is the stable **RF**… id (same order as TAP `ok N …` in this file).

| # | Test | What it checks |
| -: | ---- | ---------------- |
| RF1 | `happy-path persists facts-only result with all concerns false` | All required checks pass; `concerns` all `false`; persisted artefact omits `required_check_ids` and `custom_issue_policy`. |
| RF2 | `incomplete-required forces concerns.incomplete=true` | One required `audit_check_id` inconclusive, another missing → `concerns.incomplete=true`. |
| RF3 | `issue-routed sets concerns.security and concerns.freshness` | Routed `security` + `staleness` `issue` rows → both `security` and `freshness` concerns true. |
| RF4 | `policy-none-route excludes custom issue from security/freshness without forcing incomplete` | `custom_issue_policy.routes_by_audit_check_id` `"none"` excludes the `custom` issue cleanly. |
| RF5 | `skipped-only sets concerns.skipped=true and other concerns false` | One `skipped` row, no required ids → `concerns.skipped=true` only. |
| RF6 | `validation-fail audit stdout fails validation and writes no result.json` | Forbidden top-level `summary` on audit stdout → runner exits non-zero; `validation_fail/review.result.json` is not created. |
| RF7 | `./review/review-debug.sh --help prints usage and exits 0` | Maintainer harness emits usage with `Usage: review-debug.sh` + `run-e2e` mode line. |
| RF8 | `./review/review-debug.sh run-e2e happy-path --show-concerns succeeds and prints concerns keys` | End-to-end run via the harness includes `Derived concerns` and all four `concerns` keys. |
| RF9 | `./review/review-debug.sh run-e2e validation-fail exits non-zero with diagnostic` | Harness propagates audit measurement validation failure with the same diagnostic string. |

## Commands catalog (`docker/commands-tests.bats`)

Each row is one `@test`; labels **C**… are stable ids. Tests run with `WSL_BUILDS_COMMAND_TEST_ROOT` so scripts read/write seeded files under `$CMD_ROOT/etc/...` (no host `/etc` changes).

| # | Test | What it checks |
| -: | ---- | ---------------- |
| C1 | `apt-mirror-switch with no args prints usage and current mirror` | Seeded canonical `ubuntu.sources`; status 0; usage mentions `canonical` / `uni-of-kent`; `Current mirror: canonical`. |
| C2 | `apt-mirror-switch classifies mixed Ubuntu archive URLs` | Mixed URIs → `Current mirror: mixed`. |
| C3 | `apt-mirror-switch switches Kent ubuntu.sources to canonical (root)` | Kent URIs rewritten to archive + security hosts; classifier reports canonical. |
| C4 | `apt-mirror-switch switches canonical ubuntu.sources to uni-of-kent (root)` | Canonical URIs → mirrorservice URLs; classifier reports uni-of-kent. |
| C5 | `apt-mirror-switch rejects unknown mirror` | Exit **2**, `Unknown mirror` in output. |
| C6 | `apt-mirror-switch with too many args fails` | Exit **1**, extra positional rejected. |
| C7 | `change-hostname with no args prints usage and fails` | Exit **1**; `Usage:` in output. |
| C8 | `change-hostname updates wsl.conf and hosts under test root` | Hostname applies under test root `/etc`. |

## Wizard catalog (`docker/conf-wizard-tests.bats`)

Each test uses a fresh fake `$HOME`; [`run-bats.sh`](docker/run-bats.sh) runs this file **after [`review-fixture-tests.bats`](docker/review-fixture-tests.bats)** (and before [`commands-tests.bats`](docker/commands-tests.bats)). Each row is one `@test`. TAP numbers follow file order; labels **W**… are stable ids.

| # | Test | What it checks |
| -: | ---- | -------------- |
| W1 | `--help` exits 0 and prints usage | Status 0; output contains `Usage:`. |
| W2 | Unknown option fails | Nonzero; `Unknown option` in output. |
| W3 | `--noninteractive` creates `~/.wsl-builds.conf` from example | Linux-only env (no host default): file created under fake `$HOME`; output mentions example. |
| W4 | `--noninteractive` when home conf exists is no-op | `already exists` message; file checksum unchanged. |
| W5 | Non-TTY stdin auto-forces noninteractive | `./configure.sh </dev/null` copies example when missing (same class as W3). |
| W6 | `--defaults` rejected | `Unknown option` (alias removed); nonzero exit. |
| W7 | No managed shell rc markers after noninteractive without host default | No legacy `(managed)` or `wsl-builds:wsl-builds-conf` in fake `$HOME` `~/.bashrc` / `~/.zshrc` if present. |
| W8 | `removeManagedShellRcRegion` with no `~/.bashrc` | No-op; no error (sourced script). |
| W9 | `removeManagedShellRcRegion` strips named region only | Outside lines survive; inner lines removed. |
| W10 | `removeManagedShellRcRegion` with no markers | File byte-for-byte unchanged. |
| W11 | `replaceManagedShellRcRegion` replace / idempotent | Two calls → one block; final `WSL_BUILDS_CONF` path is the second. |
| W12 | Path quoting in managed block | Path with spaces and `$`; `source ~/.bashrc` exports correct value. |
| W13 | `normalizeHostConfPath` absolute readable | Returns same path. |
| W14 | `normalizeHostConfPath` empty input | Fails. |
| W15 | `normalizeHostConfPath` non-absolute | Fails without `wslpath` success (Linux image). |
| W16 | Pre-seeded legacy managed `~/.bashrc` block stripped on fall-through | `--noninteractive` removes legacy markers; no `wsl-builds:wsl-builds-conf` region added; surrounding lines kept. |
| W17 | Shell hint warns when `WSL_BUILDS_CONF` is set in env | `WSL_BUILDS_CONF=/path … --noninteractive` → `WARN: WSL_BUILDS_CONF still set`. |
| W18 | Shell hint silent when `WSL_BUILDS_CONF` is unset | `--noninteractive` with no env var → no `still set` line. |
| W19 | `replaceManagedShellRcRegion` with bash and zsh | When both rc files exist, each gets exactly one `wsl-builds-conf` block and the same `export`. |
