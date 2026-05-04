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
* Install ShellCheck `./build.sh dev-bash shellcheck`

### Testing
* [Bats](https://bats-core.readthedocs.io/en/stable/) is used as a testing framework for the bash scripts.
* Bats tests are run in an isolated Docker container for safety and consistency.
* `./test/run-tests.sh` to run all tests.
* See **[`test/README.md`](test/README.md)** for more info.
* Install Bats `./build.sh dev-bash bats`

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

Each build directory under **`builds/<name>/`** has a **`conf.sh`** that calls **`registerBuildMetadata`** (defined in [`src/build-metadata.sh`](src/build-metadata.sh)). Pass the build directory name (`BUILD_DIR_NAME`, usually the same as the directory basename), version string, comma-separated **`VALID_INSTALL_COMPONENTS`**, and **`NUM_ADDITIONAL_ARGS`**. The **`ai-resources`** build sets **`PROJECT_DIR`** from optional repo-root **`AI_RESOURCES_PROJECT_DIR`** in **`wsl-builds.conf`** (default **`$HOME/ai-resources`**) for its **`install_<component>.sh`** scripts.

Each **`install.sh`** is a thin wrapper: it sources **`src/install-dispatch.sh`**, where the loop runs **at top level** when sourced from **`build.sh`** (positional args propagate; do not execute `install.sh` as a standalone script). Adding a component means extending the CSV in **`registerBuildMetadata`'s third argument** and adding **`install_<name>.sh`**, using underscores for hyphenated component tokens (example: **`mysql-client`** maps to **`install_mysql_client.sh`**). **`install-dispatch.sh`** calls **`recordComponentSuccess`** using the canonical component token (including hyphens) so `~/.wsl-build.info` lines stay stable.

Do not duplicate per-component `if`/`source` blocks in **`install.sh`**; that logic lives in **`src/install-dispatch.sh`**.

For **`~/.bashrc`** / **`~/.zshrc`** and **`/etc/wsl.conf`** changes, prefer **`ensureShellRcRegion`**, **`replaceManagedShellRcRegion`**, and **`removeManagedShellRcRegion`** ([`src/shell-rc.sh`](src/shell-rc.sh)), and **`ensureWslConfIniLine`** ([`src/wsl-conf.sh`](src/wsl-conf.sh)), sourced by **`build.sh`** and **`configure.sh`**, over ad hoc **`grep`**, append, and **`sed`**.

### Repo root `README.md`

When you change user-visible builds or components, update the **Build List** in the repo root `README.md`. That file is for **people using the project** (install, `./build.sh`, the list itself). Do not add meta lines that explain how the document or table is formatted or maintained—forbidden examples include “one row per build” or “bold means …”. Editorial conventions belong in **`.cursor/rules/readme-user-facing.mdc`** and contributor context here, not in the user-facing README.

#### Build List columns: Packages & Frameworks vs Tools & extras

Before adding a component to the table, read its `install_<component>.sh` and decide which column it belongs in:

* **Packages & Frameworks** — substantive software the build installs or pulls in as the main deliverable:
  * OS/repo packages and vendor installers (apt, `.deb`, official scripts): runtimes, SDKs, daemons, databases, CUDA toolkits, **`docker`**, **`awscli`**, **`shellcheck`**, **`bats`**, **`hugo`**, **`jekyll`**, **`ollama`**, feature installs that primarily add packages (**`x11-apps`**, **`smbclient`** / **`cifs-utils`**, **`nfs-common`**, **`systemd`** packages, **`wslu`**, etc.).
  * **Framework / stack installers** via npm/yarn/pip/conda or similar: **`react`**, **`nextjs`**, **`angular`**, **`vue`**, **`express`** (dev-js); **`sg3`**, **`lsd`**, **`spleeter`**, **`rudalle`** (ai-resources).
  * Infra CLIs delivered as installed products: **`terraform`**, **`packer`**, **`kubectl`**, **`k9s`** (devops).
  * Baseline bundles whose primary job is installing packages: **`essentials`**, **`update`** (**system**, **dev**), plus **`node`**, **`nvm`**, **`yarn`**, **`python3`**, **`conda`**.

* **Tools & extras** — configuration, QoL, thin wrappers, DX layers on top of an existing runtime, or fixes that do not deliver the named stack:
  * npm globals that only add editor/lint/serve workflow (**`dev-js` `essentials`**: TypeScript, ESLint, Prettier, PM2, nodemon, serve).
  * **`qol`** components, **`fstab`** (mostly `/etc/wsl.conf`), **`vscode`** (launcher only), **`cursor`** (alias + small adjunct install), **`devops-aws` `qol`**.
  * **`cuda-wsl-lib-symlinks`** (symlink fix + `ldconfig` only).

Quick decision rule: **substantive install or framework/stack scaffold → Packages & Frameworks.** **Config, QoL, aliases, IDE launch wrappers, DX-only tooling, or symlink/workaround fixes → Tools & extras.** Mixed components (e.g. `cursor`) categorize by **primary purpose**, not by whether any `apt install` appears.

### Components

#### apt conventions

When a component uses Ubuntu `apt` (not local `.deb` installs that never hit the index):

* Run **`sudo apt update`** before any **`sudo apt install`** that pulls from a repository. Skip `apt update` for local `.deb` / `dpkg -i` flows where the index is not queried.
* Pass **`-y`** on every **`sudo apt install`**.
* Prefer **`apt`**, not **`apt-get`** (match the majority style in the repo).
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

* The `build.sh` tool will exit on any error
  * This is by choice (simple by design)
  * But means you cannot cleanup / handle errors inside the install scripts
* Use the `getFile` helper function to get any installation files
  * This will cache the files
  * Uses `/tmp` working directory, so if a subsequent command errors they are cleanued up on restart.
  * You should use the partner function `cleanupGetFiles()` to cleanup downloaded files (if desired) after running installers
* For **large or durable caches** (model weights, toolchain caches, etc.), optional variables in repo-root **`wsl-builds.conf`** (sourced before installs) can point at a host path; add commented examples to **`wsl-builds.conf.example`** and gate in the install script with **`[ -n "${VAR:-}" ]`**. **`ai-resources`** uses **`AI_RESOURCES_PROJECT_DIR`** for the clone root (default **`$HOME/ai-resources`**; see **`builds/ai-resources/conf.sh`**). See also **`builds/ai-resources/install_sg3.sh`** and **`builds/ai/install_ollama.sh`**. Details: **`.cursor/rules/bash-component-patterns.mdc`**.
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
* **Optional:** when a version command exists, prefer `printInfo "<Name> version: $(…)"` (or the first line of output) instead of ending on raw `--version` stdout. No fallbacks like `2>/dev/null || echo …`; `set -e` in `build.sh` is the error contract (`cd … || exit` is the only routine guard).

See [`builds/dev-js/install_node.sh`](builds/dev-js/install_node.sh) for a full example (including `getFile` / `cleanupGetFiles`).

**Optional: disable start on boot (systemd)** — If a vendor installer or package enables a daemon at boot (common for databases, LLM runners, etc.), you may add an interactive opt-out: after the install steps, use **`promptYesNo`** and **`sudo systemctl disable --now <unit>`** (stop now if running; omit generic **`src/`** helpers—encode multi-unit order in the component script, e.g. Docker), gated on **`systemctl`** and the unit being present. **`builds/ai/install_ollama.sh`**, **`builds/devops/install_docker.sh`**, **`builds/db/install_mysql_server.sh`**, and **`builds/db/install_postgres_server.sh`** illustrate the pattern; full conventions live in **`.cursor/rules/bash-component-patterns.mdc`**. Document new prompts in the build **`README.md`**; new prompt strings affect **`test/`** if anything asserts on output.

## FAQ
* Ubuntu only?
    * Yes. Atm this is completely geared for my needs
    * A pattern to support other distributions's will probably never come, unless...
    * I have a need for another base distribution
    * This repo gets lots of followers/stars and requests for such a feature
