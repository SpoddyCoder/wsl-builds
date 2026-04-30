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
  * `./src/lint.sh` — lint the whole repo
  * `./src/lint.sh path/to/script.sh` — lint specific files
* Install ShellCheck `./build.sh dev-bash shellcheck`.

## Testing

* **Lint (ShellCheck + `bash -n`):** `./src/lint.sh`
* **`bats` / [`build.sh`](build.sh) regressions:** all suites live under [`test/container-isolated/`](test/container-isolated/) and run inside **Docker** (same [`Dockerfile`](Dockerfile) / command as [.github/workflows/test.yml](.github/workflows/test.yml); includes noop **`test-fixture`** harness + CLI early-exit cases). Prefer the entry script so **`wsl-builds.conf`** matches [`wsl-builds.conf.container.example`](wsl-builds.conf.container.example):

```bash
docker build -t wsl-builds-test .
docker run --rm -v "$(pwd):/repo" -w /repo \
  wsl-builds-test \
  bash ./test/container-isolated/run-bats-in-container.sh
```

Details: [`docs/testing-requirements.md`](docs/testing-requirements.md). CI: [`.github/workflows/test.yml`](.github/workflows/test.yml).

## Contributing builds / components

### Metadata and dispatch (`conf.sh`, `install.sh`)

Each build directory has a **`conf.sh`** that calls **`registerBuildMetadata`** (defined in [`src/build-metadata.sh`](src/build-metadata.sh)). Pass the build directory name (`BUILD_DIR_NAME`, usually the same as the directory basename), version string, comma-separated **`VALID_INSTALL_COMPONENTS`**, and **`NUM_ADDITIONAL_ARGS`**. For **`ai-resources`** only, pass a fifth argument for **`PROJECT_DIR`** (`"${HOME}/ai-resources"`), consumed by sibling `install_<component>.sh` scripts.

Each **`install.sh`** is a thin wrapper: it sources **`src/install-dispatch.sh`**, where the loop runs **at top level** when sourced from **`build.sh`** (positional args propagate; do not execute `install.sh` as a standalone script). Adding a component means extending the CSV in **`registerBuildMetadata`'s third argument** and adding **`install_<name>.sh`**, using underscores for hyphenated component tokens (example: **`mysql-client`** maps to **`install_mysql_client.sh`**). **`install-dispatch.sh`** calls **`recordComponentSuccess`** using the canonical component token (including hyphens) so `~/.wsl-build.info` lines stay stable.

Do not duplicate per-component `if`/`source` blocks in **`install.sh`**; that logic lives in **`src/install-dispatch.sh`**.

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
