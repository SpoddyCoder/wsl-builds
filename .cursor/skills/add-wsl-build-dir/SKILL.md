---
name: add-wsl-build-dir
description: Scaffold a new wsl-builds build directory with the standard framework (conf.sh, install.sh, README.md) and no components yet. Use when the user asks to create, scaffold, initialise, or bootstrap a new build directory such as dev-rust, devops-azure, or similar.
---

# Add WSL Build Directory

Use this skill to scaffold a brand-new build directory with no components yet. Components are added afterwards via the `add-wsl-build-component` skill.

## Workflow

1. Read repo root [`README.md`](../../../README.md) and [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) **in full** (entire files) before scaffolding so the Build List row and contributor expectations match the rest of the repo.
2. Confirm the new build directory name. Use lowercase with hyphens, matching the convention of existing dirs (`dev`, `dev-js`, `devops-aws`, `ai-resources`).
3. Verify `builds/<build-dir>` does not already exist.
4. Create `builds/<build-dir>/conf.sh` with the metadata call below (`registerBuildMetadata`).
5. Create `builds/<build-dir>/install.sh` using only the `source` line below (no wrapper function call — dispatch runs inside `src/install-dispatch.sh`).
6. Create `builds/<build-dir>/README.md` with the skeleton headings below.
7. Add a row to the **Build List** table in the top-level `README.md` with a link to `builds/<build-dir>/` (match existing columns; see `.cursor/rules/readme-user-facing.mdc` and `.cursor/rules/bash-component-patterns.mdc` § **Repo root Build List**).
8. Run `bash -n` on the new `conf.sh` and `install.sh`.
9. Tell the user the dir is now framework-only and point them at `add-wsl-build-component` to add the first component.

## conf.sh template

```bash
registerBuildMetadata "<build-dir>" "1.0.0" "" 0
```

(`registerBuildMetadata` is defined once `conf.sh` is sourced from `./wsl-builder.sh`, which loads `src/build-metadata.sh` first. The first argument is stored as `BUILD_DIR_NAME` and should match the build directory basename — e.g. `registerBuildMetadata "dev-rust" ...` for a `dev-rust/` dir.)

## install.sh template

```bash
#!/usr/bin/env bash
# shellcheck source=src/install-dispatch.sh
source "${TOOL_DIR}/src/install-dispatch.sh"
```

(`registerBuildMetadata` is defined once `conf.sh` is sourced from `./wsl-builder.sh`; `install-dispatch.sh` runs at top level when sourced. Use `./wsl-builder.sh`, not executing `install.sh` directly.)

## README.md template

```markdown
# `<build-dir>`

## Requires

## Build Components

## Build Arguments
```

## Notes

- The new dir is intentionally non-buildable until a component is added: `./wsl-builder.sh <build-dir>` will print an empty component list and exit 1. This is expected.
- `src/arg-helpers.sh::showAvailableBuildDirs` scans `builds/*/` for dirs containing `conf.sh`, so the new dir appears in `./wsl-builder.sh` listings without further wiring.
- Defaults (version `"1.0.0"` and zero additional args) are set in `registerBuildMetadata`. Edit the second or fourth argument afterward if needed; add components via the CSV third argument once `add-wsl-build-component` is used.
- `conf.sh` and `install.sh` are sourced (not executed); `install.sh` has a shebang for consistency and local `shellcheck`; `conf.sh` does not require a shebang.
- If the user asks for something that sounds like `test-fixture` (noop components, CI-only), read [`builds/test-fixture/README.md`](../../../builds/test-fixture/README.md) and [`test/README.md`](../../../test/README.md) first. `test-fixture` is **not** a README “Build List” build unless the maintainer explicitly asks to list it—it exists for Bats in Docker.
- When adding the first real component, follow **Component messaging** and the minimal `install_<component>.sh` template in the `add-wsl-build-component` skill (open/close `printInfo`, helpers-only status, optional version line).

## Verification

```bash
bash -n builds/<build-dir>/conf.sh
bash -n builds/<build-dir>/install.sh
```

## Next steps

To add the first component, use the `add-wsl-build-component` skill and apply its messaging rules to the new `install_<component>.sh`.
