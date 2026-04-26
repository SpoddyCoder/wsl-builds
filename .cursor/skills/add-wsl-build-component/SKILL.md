---
name: add-wsl-build-component
description: Add or update install components in wsl-builds using the repository's standard component pattern and helper functions. Use when the user asks to create, scaffold, or modify a component in dev, system, devops, ai, db, or related build directories.
---

# Add WSL Build Component

Use this skill when adding or changing a build component in this repository.

## Workflow

1. Identify the target build directory. Valid build directories are directories containing both `conf.sh` and `install.sh`, such as `dev`, `dev-js`, `system`, or `devops`.
2. Read the target build's `conf.sh`, `install.sh`, and nearby `install_<component>.sh` files before editing.
3. Add the component name to `VALID_INSTALL_COMPONENTS` in `conf.sh`.
4. Add a matching dispatcher block to `install.sh`.
5. Put install logic in `install_<component>.sh`.
6. Update `README.md` if the component should appear in the build list.
7. Run Bash syntax checks for touched shell files.

## Dispatcher Pattern

Use the existing pattern in the target build's `install.sh`:

```bash
if [ ! -z $INSTALL_COMPONENT ]; then
    if ! isComponentInstalled "component" "$@"; then
        source ${SCRIPT_DIR}/install_component.sh
        recordComponentSuccess "component"
    else
        warnComponentAlreadyInstalled "component"
    fi
fi
```

For component names with hyphens, remember that `declareInstallComponents` converts hyphens to underscores for the `INSTALL_...` variable.

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

After editing, run targeted syntax checks:

```bash
bash -n build.sh
bash -n src/*.sh
bash -n <build-dir>/conf.sh
bash -n <build-dir>/install.sh
bash -n <build-dir>/install_<component>.sh
```

If `shellcheck` is installed, run it on the touched shell files and fix clear issues that fit the existing style.
