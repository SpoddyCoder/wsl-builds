---
name: add-wsl-build-dir
description: Scaffold a new wsl-builds build directory with the standard framework (conf.sh, install.sh, README.md) and no components yet. Use when the user asks to create, scaffold, initialise, or bootstrap a new build directory such as dev-rust, devops-azure, or similar.
---

# Add WSL Build Directory

Use this skill to scaffold a brand-new build directory with no components yet. Components are added afterwards via the `add-wsl-build-component` skill.

## Workflow

1. Confirm the new build directory name. Use lowercase with hyphens, matching the convention of existing dirs (`dev`, `dev-js`, `devops-aws`, `ai-resources`).
2. Verify the directory does not already exist at the repo root.
3. Create `<build-dir>/conf.sh` with the metadata block below.
4. Create `<build-dir>/install.sh` with just the header and `SCRIPT_DIR` line; no dispatcher blocks yet.
5. Create `<build-dir>/README.md` with the skeleton headings below.
6. Append a bare entry `* [<build-dir>](<build-dir>/)` to the end of the "Build List" section in the top-level `README.md`.
7. Run `bash -n` on the new `conf.sh` and `install.sh`.
8. Tell the user the dir is now framework-only and point them at `add-wsl-build-component` to add the first component.

## conf.sh template

```bash
HOSTNAME="<build-dir>"
BUILD_VER="1.0.0"
VALID_INSTALL_COMPONENTS=""
NUM_ADDITIONAL_ARGS=0
```

## install.sh template

```bash
#!/usr/bin/env bash

SCRIPT_DIR="<build-dir>"
```

## README.md template

```markdown
# `<build-dir>`

## Requires

## Build Components

## Build Arguments
```

## Notes

- The new dir is intentionally non-buildable until a component is added: `./build.sh <build-dir>` will print an empty component list and exit 1. This is expected.
- `src/arg-helpers.sh::showAvailableBuildDirs` auto-discovers any dir containing `conf.sh`, so the new dir appears in `./build.sh` listings without further wiring.
- Defaults (`HOSTNAME`, `BUILD_VER`, `NUM_ADDITIONAL_ARGS`) are set silently. The user can edit `conf.sh` afterwards if they need different values.
- `conf.sh` and `install.sh` are sourced (not executed); no shebang on `conf.sh` and no chmod needed.

## Verification

```bash
bash -n <build-dir>/conf.sh
bash -n <build-dir>/install.sh
```

## Next steps

To add the first component, use the `add-wsl-build-component` skill.
