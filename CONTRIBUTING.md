# Contributing
Requests, advice and PR's are welcome.

## Things To Note
* Simple by design
* This is not a package manager!
* Ultimately, this is just a collection simple bash scripts to install / configure common components and useful helpers.
  * Saves looking up install instructions
  * Automates the install procedure
  * Acts as an NB for quality of life additions

## Linting
* Bash scripts are linted with [ShellCheck](https://www.shellcheck.net/) on every push and PR.
* Run the same checks locally before pushing:
  * `./test/lint.sh` — lint the whole repo
  * `./test/lint.sh path/to/script.sh` — lint specific files
* Install ShellCheck `./build.sh dev-bash shellcheck`.

## Testing

See **[`test/README.md`](test/README.md)** for lint vs Docker/Bats, CI pointers, harness layout, and a catalog of each Bats case.


## Contributing builds / components

### Metadata and dispatch (`conf.sh`, `install.sh`)

Each build directory has a **`conf.sh`** that calls **`registerBuildMetadata`** (defined in [`src/build-metadata.sh`](src/build-metadata.sh)). Pass the build directory name (`BUILD_DIR_NAME`, usually the same as the directory basename), version string, comma-separated **`VALID_INSTALL_COMPONENTS`**, and **`NUM_ADDITIONAL_ARGS`**. For **`ai-resources`** only, pass a fifth argument for **`PROJECT_DIR`** (`"${HOME}/ai-resources"`), consumed by sibling `install_<component>.sh` scripts.

Each **`install.sh`** is a thin wrapper: it sources **`src/install-dispatch.sh`**, where the loop runs **at top level** when sourced from **`build.sh`** (positional args propagate; do not execute `install.sh` as a standalone script). Adding a component means extending the CSV in **`registerBuildMetadata`'s third argument** and adding **`install_<name>.sh`**, using underscores for hyphenated component tokens (example: **`mysql-client`** maps to **`install_mysql_client.sh`**). **`install-dispatch.sh`** calls **`recordComponentSuccess`** using the canonical component token (including hyphens) so `~/.wsl-build.info` lines stay stable.

Do not duplicate per-component `if`/`source` blocks in **`install.sh`**; that logic lives in **`src/install-dispatch.sh`**.

### Repo root `README.md`

When you change user-visible builds or components, update the **Build List** in the repo root `README.md`. That file is for **people using the project** (install, `./build.sh`, the list itself). Do not add meta lines that explain how the document or table is formatted or maintained—forbidden examples include “one row per build” or “bold means …”. Editorial conventions belong in **`.cursor/rules/readme-user-facing.mdc`** and contributor context here, not in the user-facing README.

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
* For **large or durable caches** (model weights, toolchain caches, etc.), optional variables in repo-root **`wsl-builds.conf`** (sourced before installs) can point at a host path; add commented examples to **`wsl-builds.conf.example`** and gate in the install script with **`[ -n "${VAR:-}" ]`**. See **`ai-resources/install_sg3.sh`** and **`ai/install_ollama.sh`**. Details: **`.cursor/rules/bash-component-patterns.mdc`**.
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

See [`dev-js/install_node.sh`](dev-js/install_node.sh) for a full example (including `getFile` / `cleanupGetFiles`).

## FAQ
* Ubuntu only?
    * Yes. Atm this is completely geared for my needs
    * A pattern to support other distributions's will probably never come, unless...
    * I have a need for another base distribution
    * This repo gets lots of followers/stars and requests for such a feature
