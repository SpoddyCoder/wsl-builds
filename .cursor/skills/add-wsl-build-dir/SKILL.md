---
name: add-wsl-build-dir
description: Scaffold a new wsl-builds build directory with the standard framework (conf.sh, install.sh, README.md) and no components yet. Use when the user asks to create, scaffold, initialise, or bootstrap a new build directory such as dev-rust, devops-azure, or similar.
---

# Add WSL Build Directory

Use this skill to scaffold a brand-new build directory with no components yet. Components are added afterwards via the `add-wsl-build-component` skill.

## Workflow

1. Confirm the new build directory name. Use lowercase with hyphens, matching the convention of existing dirs (`dev`, `dev-js`, `devops-aws`, `ai-resources`).
2. Verify the directory does not already exist at the repo root.
3. Create `<build-dir>/conf.sh` with the metadata call below (`registerBuildMetadata`).
4. Create `<build-dir>/install.sh` using only the **`source`** line below (no wrapper function call — dispatch runs inside `src/install-dispatch.sh`).
5. Create `<build-dir>/README.md` with the skeleton headings below.
6. Append a bare entry `* [<build-dir>](<build-dir>/)` to the end of the "Build List" section in the top-level `README.md`.
7. Run `bash -n` on the new `conf.sh` and `install.sh`.
8. Tell the user the dir is now framework-only and point them at `add-wsl-build-component` to add the first component.

## conf.sh template

```bash
registerBuildMetadata "<build-dir>" "1.0.0" "" 0
```

(`registerBuildMetadata` is defined once `conf.sh` is sourced from `./build.sh`, which loads `src/build-metadata.sh` first. The first argument is stored as **`BUILD_DIR_NAME`** and should match the build directory basename — e.g. `registerBuildMetadata "dev-rust" ...` for a `dev-rust/` dir.)

## install.sh template

```bash
#!/usr/bin/env bash
# shellcheck source=src/install-dispatch.sh
source "${TOOL_DIR}/src/install-dispatch.sh"
```

(`registerBuildMetadata` is defined once `conf.sh` is sourced from `./build.sh`; `install-dispatch.sh` runs at top level when sourced. Use **`./build.sh`**, not executing `install.sh` directly.)

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
- Defaults (version `"1.0.0"` and zero additional args) are set in **`registerBuildMetadata`**. Edit the second or fourth argument afterward if needed; add components via the CSV third argument once `add-wsl-build-component` is used.
- `conf.sh` and `install.sh` are sourced (not executed); `install.sh` has a shebang for consistency and local `shellcheck`; `conf.sh` does not require a shebang.
- If the user asks for something that sounds like **`test-fixture`** (noop components, harness-only CI), read **[`docs/testing-requirements.md`](../../../docs/testing-requirements.md)** first. **`test-fixture`** is **not** a README “Build List” stack unless the maintainer explicitly asks to list it—it exists for automated/container-isolated **bats**.

## Verification

```bash
bash -n <build-dir>/conf.sh
bash -n <build-dir>/install.sh
```

## Next steps

To add the first component, use the `add-wsl-build-component` skill.
