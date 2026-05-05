# Contributing
Requests, advice and PR's are welcome.

## Things To Note
* Simple by design
* This is not a package manager!
* Ultimately, this is just a collection simple bash scripts to install / configure common components and useful helpers.
  * Saves looking up install instructions
  * Automates the install procedure
  * Acts as an NB for quality of life additions

### Linting
* Bash scripts are linted with [ShellCheck](https://www.shellcheck.net/).
* `./test/lint.sh` — lint the whole repo
* `./test/lint.sh path/to/script.sh` — lint specific files
* Install ShellCheck `./wsl-builder.sh dev-bash shellcheck`

### Testing
* [Bats](https://bats-core.readthedocs.io/en/stable/) is used as a testing framework for the bash scripts.
* Bats tests are run in an isolated Docker container for safety and consistency.
* `./test/run-tests.sh` to run all tests.
* See **[`test/README.md`](test/README.md)** for more info.
* Install Bats `./wsl-builder.sh dev-bash bats`

### CI
* Lint + Bats tests are run on every push and PR.
* See: [`.github/workflows`](.github/workflows)

---

## Contributing builds / components
* This project is AI assisted.
* [Rules](./.cursor/rules) help the AI agent understand the project and its conventions.
* In almost all cases, you can simply ask the AI agent to use the [skills](./.cursor/skills) to add new things.
  * [add-wsl-build-dir](./.cursor/skills/add-wsl-build-dir/SKILL.md)
  * [add-wsl-build-component](./.cursor/skills/add-wsl-build-component/SKILL.md)
  * [review-wsl-build-component](./.cursor/skills/review-wsl-build-component/SKILL.md)
* In addition to adding the new builds / components, it will read this guide and automatically take care of docs and tests etc.

### Metadata and dispatch (`conf.sh`, `install.sh`)

Each build directory under `builds/<name>/` has a `conf.sh` that calls `registerBuildMetadata` (defined in [`src/build-metadata.sh`](src/build-metadata.sh)). Pass the build directory name (`BUILD_DIR_NAME`, usually the same as the directory basename), version string, comma-separated `VALID_INSTALL_COMPONENTS`, and `NUM_ADDITIONAL_ARGS`. The `ai-resources` build sets `PROJECT_DIR` from optional `AI_RESOURCES_PROJECT_DIR` in user `wsl-builds.conf` (sourced by `./wsl-builder.sh` as `WSL_BUILDS_CONF` or `~/.wsl-builds.conf`) (default `$HOME/ai-resources`) for its `install_<component>.sh` scripts.

Each `install.sh` is a thin wrapper: it sources `src/install-dispatch.sh`, where the loop runs **at top level** when **the builder** (`./wsl-builder.sh`) sources `install.sh` (positional args propagate; do not execute `install.sh` as a standalone script). Adding a component means extending the CSV in the third argument to `registerBuildMetadata` and adding `install_<name>.sh`, using underscores for hyphenated component tokens (example: `mysql-client` maps to `install_mysql_client.sh`). `install-dispatch.sh` calls `recordComponentSuccess` using the canonical component token (including hyphens) so `~/.wsl-build.info` lines stay stable.

Do not duplicate per-component `if`/`source` blocks in `install.sh`; that logic lives in `src/install-dispatch.sh`.

For `~/.bashrc` / `~/.zshrc` and `/etc/wsl.conf` changes, prefer `ensureShellRcRegion`, `replaceManagedShellRcRegion`, and `removeManagedShellRcRegion` ([`src/shell-rc.sh`](src/shell-rc.sh)), and `ensureWslConfIniLine` ([`src/wsl-conf.sh`](src/wsl-conf.sh)), sourced by `./wsl-builder.sh` and `configure.sh`, over ad hoc `grep`, append, and `sed`.

### Repo root `README.md`

When you change user-visible builds or components, update the **Build List** in the repo root `README.md`. That file is for **people using the project** (install, `./wsl-builder.sh`, the list itself). Do not add meta lines that explain how the document or table is formatted or maintained—forbidden examples include “one row per build” or “bold means …”. Editorial conventions belong in `.cursor/rules/readme-user-facing.mdc` and contributor context here, not in the user-facing README.

#### Build List columns: middle vs Additional Conf

The **Build List** table has three columns: **Build** | **Packages, Frameworks, Tools & Extras** | **Additional Conf**.

* **Packages, Frameworks, Tools & Extras** — every component for that build (bold component token, short description). Read each `install_<component>.sh` first. For readability, list **substantive installs and framework/stack scaffolds** before **config, QoL, wrappers, DX-only layers, and workaround fixes** in the same cell:
  * *Substantive* — OS/repo/vendor packages (runtimes, SDKs, CUDA, databases, `docker`, `awscli`, infra CLIs, `x11` / `smb` / `nfs` / `systemd` / `wslu` stacks), framework installers (`react`, `nextjs`, etc.; **ai-resources** components), baseline `essentials` / `update`, `node` / `nvm` / `yarn`, `python3` / `conda`, `shellcheck`, `bats`, `hugo`, `jekyll`, `ollama`.
  * *QoL / thin / fix* — `dev-js` `essentials` (npm globals), `qol`, `fstab`, `vscode`, `cursor`, `devops-aws` `qol`, `cuda-wsl-lib-symlinks`.
  * Mixed components (e.g. `cursor`): order by **primary purpose**, not by whether any `apt install` appears.

* **Additional Conf** — keys in user `wsl-builds.conf` that this build’s components read (see `wsl-builds.conf.example`). Prefix each group with `component`: like the middle column (e.g. **ollama** then the keys). Separate logical groups with `<br/>`. **Line width:** keep each visual line about **30 characters or fewer** (approximate); insert extra `<br/>` so no line exceeds that length without **splitting tokens** (do not break inside an env var name, a glob like `GIT_*`, or a bold component label). If one key is shared by every component in the build, use a comma-separated list of bold component tokens before the colon (**ai-resources** table: **sg3**, **lsd**, **spleeter**, **rudalle**). Leave the cell empty when nothing applies. Omit builder-global keys (`CACHE_DIR`, `EXTERNAL_BUILDS_ROOT`, etc.) from per-build rows unless you have a strong reason to repeat them.

### Components

#### apt conventions

When a component uses Ubuntu `apt` (not local `.deb` installs that never hit the index):

* Run `sudo apt update` before any `sudo apt install` that pulls from a repository. Skip `apt update` for local `.deb` / `dpkg -i` flows where the index is not queried.
* Pass `-y` on every `sudo apt install`.
* Prefer `apt`, not `apt-get` (match the majority style in the repo).
* **Golden snippet** for an apt-only component:

```bash
#!/usr/bin/env bash

printInfo "Installing Example"
sudo apt update
sudo apt install -y example-package

printInfo "Example version: $(example --version | head -n1)"
printInfo "Example installed"
```

#### Other conventions

* **The builder** (`./wsl-builder.sh`) will exit on any error
  * This is by choice (simple by design)
  * But means you cannot cleanup / handle errors inside the install scripts
* Use the `getFile` helper function to get any installation files
  * This will cache the files
  * Uses `/tmp` working directory, so if a subsequent command errors they are cleanued up on restart.
  * You should use the partner function `cleanupGetFiles()` to cleanup downloaded files (if desired) after running installers
* For **large or durable caches** (model weights, toolchain caches, etc.), optional variables in user `wsl-builds.conf` (sourced before installs; `WSL_BUILDS_CONF` or `~/.wsl-builds.conf`) can point at a host path; add commented examples to `wsl-builds.conf.example` and gate in the install script with `[ -n "${VAR:-}" ]`. `ai-resources` uses `AI_RESOURCES_PROJECT_DIR` for the clone root (default `$HOME/ai-resources`; see `builds/ai-resources/conf.sh`). See also `builds/ai-resources/install_sg3.sh` and `builds/ai/install_ollama.sh`. Details: `.cursor/rules/bash-component-patterns.mdc`.
* Use the `isComponentInstalled` helper function to check if components are already installed
  * This checks `~/.wsl-build.info` for component records and respects the `--force` flag
  * Returns 0 (true) if component is installed, 1 (false) if not installed or `--force` is used
* Use the `warnComponentAlreadyInstalled` helper function for consistent warning messages
  * This provides a standard warning format when components are already installed
  * Automatically includes the component name and `--force` override instruction
* Use the `recordComponentSuccess` helper function to record successful component installations
  * This immediately records the component to `~/.wsl-build.info` and sets `BUILD_UPDATED=true`
  * This ensures that successful components are recorded even if later components fail

#### Component messaging

Each `install_<component>.sh` should follow one small pattern so output stays consistent:

* **Open** with one line: `printInfo "Installing <Name>"` (human-readable name; reuse that noun when you close).
* **In progress:** use `printInfo` for step lines without ellipsis (`…` / `...`)—same tone as the closing line.
* **Close** with one final line: `printInfo "<Name> installed"` — past tense, no “successfully”, no ellipsis, no trailing period. This must be the **last** user-facing line (after any version check).
* Use `printInfo`, `printWarning`, and `printError` for install progress. Use `echo` only for data you are writing into a file or heredoc, not for step status.
* **Optional:** when a version command exists, prefer `printInfo "<Name> version: $(…)"` (or the first line of output) instead of ending on raw `--version` stdout. No fallbacks like `2>/dev/null || echo …`; `set -e` in `./wsl-builder.sh` is the error contract (`cd … || exit` is the only routine guard).

See [`builds/dev-js/install_node.sh`](builds/dev-js/install_node.sh) for a full example (including `getFile` / `cleanupGetFiles`).

**Optional: disable start on boot (systemd)** — If a vendor installer or package enables a daemon at boot (common for databases, LLM runners, etc.), you may add an interactive opt-out: after the install steps, use `promptYesNo` and `sudo systemctl disable --now <unit>` (stop now if running; omit generic `src/` helpers—encode multi-unit order in the component script, e.g. Docker), gated on `systemctl` and the unit being present. `builds/ai/install_ollama.sh`, `builds/devops/install_docker.sh`, `builds/db/install_mysql_server.sh`, and `builds/db/install_postgres_server.sh` illustrate the pattern; full conventions live in `.cursor/rules/bash-component-patterns.mdc`. Document new prompts in the build `README.md`; new prompt strings affect `test/` if anything asserts on output.

## FAQ
* Ubuntu only?
    * Yes. Atm this is completely geared for my needs
    * A pattern to support other distributions's will probably never come, unless...
    * I have a need for another base distribution
    * This repo gets lots of followers/stars and requests for such a feature
