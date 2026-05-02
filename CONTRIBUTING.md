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

* **Lint only (ShellCheck + `bash -n`):** [`./test/lint.sh`](test/lint.sh) — same checks as [.github/workflows/lint.yml](.github/workflows/lint.yml); see **Linting** above.
* **Lint + Docker + Bats:** [`./test/run-tests.sh`](test/run-tests.sh) runs lint, then `docker build -f test/docker/Dockerfile` from the repo root, then `docker run` the image (lint + image build + Bats in one command). Use it from the **repo root** instead of running Bats on the host by hand. CI covers the same areas via [.github/workflows/lint.yml](.github/workflows/lint.yml) and [.github/workflows/test.yml](.github/workflows/test.yml).

```bash
./test/run-tests.sh
```

**[`bats-core`](https://github.com/bats-core/bats-core)** regressions exercise [`build.sh`](build.sh) against the noop **`test-fixture`** build; the harness and image live under [`test/docker/`](test/docker/). The image **copies the repo at build time** (no bind mount).

* **Do not** run [`test/docker/run-bats.sh`](test/docker/run-bats.sh) on the host — it overwrites repo-root **`wsl-builds.conf`**.
* **Docker test files:** [`test/docker/Dockerfile`](test/docker/Dockerfile), [`test/docker/Dockerfile.dockerignore`](test/docker/Dockerfile.dockerignore), [`test/docker/run-bats.sh`](test/docker/run-bats.sh), [`test/docker/build-test-fixture-harness.bats`](test/docker/build-test-fixture-harness.bats), [`test/docker/wsl-builds.conf`](test/docker/wsl-builds.conf).


## Contributing builds / components

### Metadata and dispatch (`conf.sh`, `install.sh`)

Each build directory has a **`conf.sh`** that calls **`registerBuildMetadata`** (defined in [`src/build-metadata.sh`](src/build-metadata.sh)). Pass the build directory name (`BUILD_DIR_NAME`, usually the same as the directory basename), version string, comma-separated **`VALID_INSTALL_COMPONENTS`**, and **`NUM_ADDITIONAL_ARGS`**. For **`ai-resources`** only, pass a fifth argument for **`PROJECT_DIR`** (`"${HOME}/ai-resources"`), consumed by sibling `install_<component>.sh` scripts.

Each **`install.sh`** is a thin wrapper: it sources **`src/install-dispatch.sh`**, where the loop runs **at top level** when sourced from **`build.sh`** (positional args propagate; do not execute `install.sh` as a standalone script). Adding a component means extending the CSV in **`registerBuildMetadata`'s third argument** and adding **`install_<name>.sh`**, using underscores for hyphenated component tokens (example: **`mysql-client`** maps to **`install_mysql_client.sh`**). **`install-dispatch.sh`** calls **`recordComponentSuccess`** using the canonical component token (including hyphens) so `~/.wsl-build.info` lines stay stable.

Do not duplicate per-component `if`/`source` blocks in **`install.sh`**; that logic lives in **`src/install-dispatch.sh`**.

### Repo root `README.md`

When you change user-visible builds or components, update the **Build List** in the repo root `README.md`. That file is for **people using the project** (install, `./build.sh`, the list itself). Do not add meta lines that explain how the document or table is formatted or maintained—forbidden examples include “one row per build” or “bold means …”. Editorial conventions belong in **`.cursor/rules/readme-user-facing.mdc`** and contributor context here, not in the user-facing README.

### Components

* The `build.sh` tool will exit on any error
  * This is by choice (simple by design)
  * But means you cannot cleanup / handle errors inside the install scripts
* Use the `getFile` helper function to get any installation files
  * This will cache the files
  * Uses `/tmp` working directory, so if a subsequent command errors they are cleanued up on restart.
  * You should use the partner function `cleanupGetFiles()` to cleanup downloaded files (if desired) after running installers
* Use the `isComponentInstalled` helper function to check if components are already installed
  * This checks `~/.wsl-build.info` for component records and respects the `--force` flag
  * Returns 0 (true) if component is installed, 1 (false) if not installed or `--force` is used
* Use the `warnComponentAlreadyInstalled` helper function for consistent warning messages
  * This provides a standard warning format when components are already installed
  * Automatically includes the component name and `--force` override instruction
* Use the `recordComponentSuccess` helper function to record successful component installations
  * This immediately records the component to `~/.wsl-build.info` and sets `BUILD_UPDATED=true`
  * This ensures that successful components are recorded even if later components fail

## FAQ
* Ubuntu only?
    * Yes. Atm this is completely geared for my needs
    * A pattern to support other distributions's will probably never come, unless...
    * I have a need for another base distribution
    * This repo gets lots of followers/stars and requests for such a feature
