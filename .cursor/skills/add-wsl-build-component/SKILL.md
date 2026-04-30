---
name: add-wsl-build-component
description: Add or update install components in wsl-builds using the repository's standard component pattern and helper functions. Use when the user asks to create, scaffold, or modify a component in dev, system, devops, ai, db, or related build directories.
---

# Add WSL Build Component

Use this skill when adding or changing a build component in this repository.

## Workflow

1. Identify the target build directory. Valid build directories are directories containing both `conf.sh` and `install.sh`, such as `dev`, `dev-js`, `system`, or `devops`. The **`test-fixture`** directory is **testing-only** ([`test-fixture/README.md`](../../../test-fixture/README.md); noop harness for CI/agents)—do **not** use it like a production stack unless explicitly asked.
2. Read the target build's `conf.sh`, `install.sh`, and nearby `install_<component>.sh` files before editing.
3. Add the component token to **the third argument (CSV)** of **`registerBuildMetadata`** in **`conf.sh`**.
4. Add **`install_<name>.sh`**, mapping hyphens to underscores in the basename (examples: **`docker-desktop`** → `install_docker_desktop.sh`; **`postgres-server`** → `install_postgres_server.sh`).
5. Leave **`install.sh`** as the thin **`source install-dispatch.sh`** stub unless you need build-specific behavior beyond **`src/install-dispatch.sh`**.
6. Update `README.md` if the component should appear in the build list.
7. Run Bash syntax checks for touched shell files.

## Dispatcher (`install.sh`)

Build directory **`install.sh`** files should remain:

```bash
#!/usr/bin/env bash
# shellcheck source=src/install-dispatch.sh
source "${TOOL_DIR}/src/install-dispatch.sh"
```

Component iteration and **`recordComponentSuccess`** live in **`src/install-dispatch.sh`** (top level when sourced from **`build.sh`**).

`declareInstallComponents` (from `src/arg-helpers.sh`) maps component tokens like **`postgres-client`** to **`INSTALL_POSTGRES_CLIENT`**. Filename mapping for `source` targets is the underscore form (**`install_postgres_client.sh`**).

## Install Script Guidelines

- Keep each component focused on one install/configuration task.
- Use `printInfo`, `printWarning`, and `printError` for output.
- Use `getFile` for downloads so files are cached through `CACHE_DIR`.
- Call `cleanupGetFiles` after using downloaded installers when cleanup is appropriate.
- Prefer existing helper functions in `src/` over new helpers.
- Do not call `recordComponentSuccess` inside `install_<component>.sh`; the dispatcher records success after the script completes.
- Avoid broad error handling that hides failures; `build.sh` runs with `set -e`.
- Preserve the repository's simple Bash style unless the user asks for a larger refactor.

## Verification

Repo-wide **`./test/lint.sh`** (ShellCheck + `bash -n`; ShellCheck **`--shell=bats`** on **`test/container-isolated/*.bats`**). After substantive harness or dispatch edits (skip for trivial one-off component scripts), run **`./test/run-tests.sh`** from the repo root (lint + Docker **`bats-core`**), per **Testing** in [`CONTRIBUTING.md`](../../../CONTRIBUTING.md).

After editing, run targeted syntax checks:

```bash
bash -n build.sh
bash -n src/*.sh
bash -n <build-dir>/conf.sh
bash -n <build-dir>/install.sh
bash -n <build-dir>/install_<component>.sh
```

If `shellcheck` is installed, run it on the touched shell files and fix clear issues that fit the existing style.
