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
6. Update the repo root `README.md` **Build List** if the component should appear there—add or edit table rows only. **Categorize by primary purpose** (read the `install_<component>.sh` first). Column headers are **Packages & Frameworks** | **Tools & extras**.
   - **Packages & Frameworks** = substantive installs: vendor/OS packages (runtimes, CUDA, databases, `docker`, `awscli`, infra CLIs such as `terraform` / `kubectl` / `k9s`, apt-backed stacks like `x11` / `smb` / `nfs` / `systemd` / `wslu`), **framework/stack installers** (`react`, `nextjs`, `angular`, `vue`, `express`; **ai-resources** components), baseline `essentials` / `update`, `node` / `nvm` / `yarn`, `python3` / `conda`.
   - **Tools & extras** = config / QoL / thin wrappers / DX-only layers (`dev-js` **`essentials`** npm globals only), `qol`, `fstab`, `vscode`, `cursor`, `devops-aws` qol, `cuda-wsl-lib-symlinks`.
   - Quick rule: **substantive install or framework/stack scaffold → Packages & Frameworks;** config, QoL, launch wrappers, DX-only tooling, symlink fixes → **Tools & extras.** Mixed cases (e.g. `cursor` `apt install`s `tree` but exists for the alias + launch) categorize by **primary purpose**, not by whether any `apt install` appears.
   - Keep that file strictly **end-user** focused (install, `./build.sh`, the list itself); do not add meta lines about table formatting or maintenance. See `.cursor/rules/readme-user-facing.mdc` and **`CONTRIBUTING.md`** § *Build List columns: Packages & Frameworks vs Tools & extras* (canonical prose).
7. **Optional `wsl-builds.conf` keys** (large downloads / durable caches the user may want on a host path): add **commented examples** to **`wsl-builds.conf.example`** and document usage in the build’s **`README.md`**. See **`.cursor/rules/bash-component-patterns.mdc`**.
8. Run Bash syntax checks for touched shell files.

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

Full conventions: [`.cursor/rules/bash-component-patterns.mdc`](../../rules/bash-component-patterns.mdc) and **Component messaging** in [`CONTRIBUTING.md`](../../../CONTRIBUTING.md).

- Keep each component focused on one install/configuration task.
- **Open** with one line: `printInfo "Installing <Name>"` (human-readable product name; use the same noun at the end).
- **Close** with one final line: `printInfo "<Name> installed"` — past tense, no "successfully", no ellipsis, no trailing period. Must be the **last** user-facing status (after any verification).
- **Channels:** use `printInfo`, `printWarning`, and `printError` for step/status output. Use `echo` only for data written into files or heredocs, not for install progress.
- **Optional:** if a natural version command exists, prefer `printInfo "<Name> version: $(cmd …)"` (or the first line of output) instead of raw `--version` stdout as the script’s last impression.
- Use `getFile` for downloads so files are cached through `CACHE_DIR`.
- Call `cleanupGetFiles` after using downloaded installers when cleanup is appropriate.
- Prefer existing helper functions in `src/` over new helpers.
- Do not call `recordComponentSuccess` inside `install_<component>.sh`; the dispatcher records success after the script completes.
- Avoid broad error handling that hides failures; `build.sh` runs with `set -e`.
- Preserve the repository's simple Bash style unless the user asks for a larger refactor.

**Golden example:** [`dev-js/install_node.sh`](../../../dev-js/install_node.sh).

### Minimal `install_<component>.sh` template

Replace `<Name>` and the body; add mid-step `printInfo` as needed. Pair `getFile` with `cleanupGetFiles` when you download.

```bash
#!/usr/bin/env bash

printInfo "Installing <Name>"

# ...

# printInfo "<Name> version: $(some-tool --version 2>&1 | head -n1)"

printInfo "<Name> installed"
```

## Verification

Repo-wide **`./test/lint.sh`** (ShellCheck + `bash -n`; ShellCheck **`--shell=bats`** on **`test/docker/*.bats`**). After substantive edits to **`src/install-dispatch.sh`**, shared helpers, or **`test/docker/`** (skip for trivial one-off component scripts), run **`./test/run-tests.sh`** from the repo root (lint + Docker Bats), per [`test/README.md`](../../../test/README.md).

After editing, run targeted syntax checks:

```bash
bash -n build.sh
bash -n src/*.sh
bash -n <build-dir>/conf.sh
bash -n <build-dir>/install.sh
bash -n <build-dir>/install_<component>.sh
```

If `shellcheck` is installed, run it on the touched shell files and fix clear issues that fit the existing style.
