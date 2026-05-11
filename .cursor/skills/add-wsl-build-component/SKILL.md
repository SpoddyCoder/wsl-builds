---
name: add-wsl-build-component
description: Add or update install components in wsl-builds using the repository's standard component pattern and helper functions. Use when the user asks to create, scaffold, or modify a component in dev, system, devops, ai, db, or related build directories.
---

# Add WSL Build Component

Use this skill when adding or changing a build component in this repository.

## Workflow

1. Read repo root [`README.md`](../../../README.md) and [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) **in full** (entire files) before editing so the Build List, tone, and contributor expectations stay aligned.
2. Identify the target build directory under `builds/<name>/`. Valid build directories contain both `conf.sh` and `install.sh`, such as `builds/dev`, `builds/dev-js`, `builds/system`, or `builds/devops`. The `builds/fixture-builder` directory is **testing-only** ([`builds/fixture-builder/README.md`](../../../builds/fixture-builder/README.md); noop harness for CI/agents)—do **not** use it like a production build unless explicitly asked.
3. Read the target build's `conf.sh`, `install.sh`, and nearby `builds/<name>/<slug>/install.sh` files before editing.
4. Add the component token to **the third argument (CSV)** of `registerBuildMetadata` in `conf.sh`.
5. Add `builds/<name>/<slug>/install.sh`, creating the `<slug>` directory as needed. Map hyphens in the token to underscores in `slug` (examples: `docker-desktop` → `docker_desktop/install.sh`; `postgres-server` → `postgres_server/install.sh`).
6. Leave the build-level `install.sh` as the thin stub that only `source`s `"${REPO_ROOT}/src/builder/install-dispatch.sh"` unless you need build-specific behavior beyond `src/builder/install-dispatch.sh`.
7. Update the repo root `README.md` **Build List** if the component should appear there—add or edit table rows only. Headers are **Build** | **Packages, Frameworks, Tools & Extras** | **Additional Conf**. Read the component `install.sh` first; put the component in the **middle** column (list substantive installs before QoL/DX-only fixes when both exist in one build). Add or update **Additional Conf** when the component reads keys from `wsl-builds.conf` (see `wsl-builds.conf.example`), using `component`: before the keys like the middle column. In **Additional Conf**, use `<br/>` so each line stays about **30 characters** (visual width, approximate) without breaking words or env var names.
   - Keep that file strictly **end-user** focused (install, `./wsl-builder.sh`, the list itself); do not add meta lines about table formatting or maintenance. See `.cursor/rules/readme-user-facing.mdc` and `.cursor/rules/bash-component-patterns.mdc` § **Repo root Build List**.
8. **Optional** `wsl-builds.conf` keys (large downloads / durable caches the user may want on a host path): add **commented examples** to `wsl-builds.conf.example` and document usage in the build’s `README.md`. See `.cursor/rules/bash-component-patterns.mdc`.
9. **Start on boot:** After you know what the component installs, check whether it enables a **systemd unit** (or equivalent) that **starts automatically on boot**. If yes, and the component script does not already offer an optional disable step, **ask the user** in chat whether to add the standard `promptYesNo` + `sudo systemctl disable --now <unit>` pattern (see `.cursor/rules/bash-component-patterns.mdc`, *Optional: disable start on boot*, and `builds/ai/ollama/install.sh`). Components with multiple systemd units encode `disable --now` and ordering locally—do not introduce a generic `src/` helper without several identical callers. Only implement after they agree—do not assume every daemon should be disabled by default.
10. **Automated advisory review (optional):** If you add or change `<slug>/audit.sh`, `<slug>/audit.manifest.yaml` (review-only files under `builds/<build>/<slug>/`), or shared code under `src/review/`, follow [`review/README.md`](../../../review/README.md) and [`docs/automated-builds-review-v1-spec.md`](../../../docs/automated-builds-review-v1-spec.md); host tools and `CONTRIBUTING.md` expectations apply.
11. If the component belongs in a shipped stack, update the relevant `stacks/<namespace>/*.wslb` and namespace `README.md`.
12. Run Bash syntax checks for touched shell files.

## Dispatcher (`install.sh`)

Build directory `install.sh` files should remain:

```bash
#!/usr/bin/env bash
# shellcheck source=src/builder/install-dispatch.sh
source "${REPO_ROOT}/src/builder/install-dispatch.sh"
```

Component iteration and `recordComponentSuccess` live in `src/builder/install-dispatch.sh` (top level when sourced from `./wsl-builder.sh`). **`./wsl-builder.sh`** sets `REPO_ROOT` before sourcing this file; see `src/common/bootstrap-common.sh` and `docs/standardise-bootstrap-plan.md`.

`declareInstallComponents` (from `src/builder/arg-helpers.sh`) maps component tokens like `postgres-client` to `INSTALL_POSTGRES_CLIENT`. Dispatch sources `builds/<name>/postgres_client/install.sh` for that token (hyphens → underscores in the directory name only).

## Install Script Guidelines

Full conventions: [`.cursor/rules/bash-component-patterns.mdc`](../../rules/bash-component-patterns.mdc) (messaging, apt, helpers, systemd opt-out, Build List).

- Keep each component focused on one install/configuration task.
- **Open** with one line: `printInfo "Installing <Name>"` (human-readable product name; use the same noun at the end).
- **Close** with one final line: `printInfo "<Name> installed"` — past tense, no "successfully", no ellipsis, no trailing period. Must be the **last** user-facing status (after any verification).
- **Channels:** use `printInfo`, `printWarning`, and `printError` for step/status output. Use `echo` only for data written into files or heredocs, not for install progress.
- **Optional:** if a natural version command exists, prefer `printInfo "<Name> version: $(cmd …)"` (or the first line of output) instead of raw `--version` stdout as the script’s last impression.
- Use `getFile` for downloads so files are cached through `CACHE_DIR`.
- Call `cleanupGetFiles` after using downloaded installers when cleanup is appropriate.
- Prefer existing helper functions in `src/` over new helpers.
- Do not call `recordComponentSuccess` inside per-component `install.sh`; the dispatcher records success after the script completes.
- Avoid broad error handling that hides failures; **the builder** (`./wsl-builder.sh`) runs with `set -e`.
- Preserve the repository's simple Bash style unless the user asks for a larger refactor.
- If the user agrees to a **disable start-on-boot** prompt, follow `.cursor/rules/bash-component-patterns.mdc` (*Optional: disable start on boot*) and mirror `builds/ai/ollama/install.sh` (and multi-unit examples such as `builds/devops/docker/install.sh`): gate on `systemctl` and the unit(s), use `promptYesNo`, run `sudo systemctl disable --now` on yes (stop now + no boot), confirm with `printInfo`; document wording in the build `README.md`.

**Golden example:** [`builds/dev-js/node/install.sh`](../../../builds/dev-js/node/install.sh).

### Minimal per-component `install.sh` template

Replace `<Name>` and the body; add mid-step `printInfo` as needed. Pair `getFile` with `cleanupGetFiles` when you download.

```bash
#!/usr/bin/env bash

printInfo "Installing <Name>"

# ...

# printInfo "<Name> version: $(some-tool --version 2>&1 | head -n1)"

printInfo "<Name> installed"
```

## Verification

Repo-wide `./test/lint.sh` (ShellCheck + `bash -n`; ShellCheck `--shell=bats` on `test/docker/*.bats`). After substantive edits to `src/builder/install-dispatch.sh`, shared helpers, or `test/docker/` (skip for trivial one-off component scripts), run `./test/run-tests.sh` from the repo root (lint + Docker Bats), per [`test/README.md`](../../../test/README.md).

If you change any **exact user-visible string** (e.g. `printInfo`/`printWarning`/`printError` lines, `getFile` cache warnings/prompts, usage text), `rg` `test/` and `builds/fixture-builder/` (especially `test/docker/*.bats`) for the old wording and update **assertions or golden substrings** in the same PR; stale regex/`grep` checks are a common regression.

After editing, run targeted syntax checks:

```bash
bash -n wsl-builder.sh
bash -n src/common/*.sh src/builder/*.sh
bash -n builds/<build-dir>/conf.sh
bash -n builds/<build-dir>/install.sh
bash -n builds/<build-dir>/<slug>/install.sh
```

If `shellcheck` is installed, run it on the touched shell files and fix clear issues that fit the existing style.
