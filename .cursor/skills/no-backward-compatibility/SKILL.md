---
name: no-backward-compatibility
description: >-
  Execute clean refactors with no backward-compatibility remnants—rename to the new design, remove old paths, and document the current system only. Use when the user says no backward compatibility, clean break, full rename, or similar; when replacing a pattern, API, or naming scheme; or when a refactor spans many files, builds, tests, or docs. Default assumption for this project; see also no-backward-compatibility.mdc.
---

# Clean refactor (no backward compatibility)

The always-on rule [no-backward-compatibility.mdc](../../rules/no-backward-compatibility.mdc) sets the default. Use this skill for **multi-file refactors** where a checklist helps avoid leaving remnants.

## Workflow

1. **Confirm scope** — What is being replaced, and what is the new name or pattern? If the user already said "no backward compatibility" or similar, do not ask again.
2. **Find all references** — Search the repo for old names, paths, env vars, config keys, and user-visible strings (`rg` across `src/`, `builds/`, `test/`, `stacks/`, `.cursor/`, root docs).
3. **Replace in one pass** — Code, tests, fixtures, rules, skills, and docs in the same change. Prefer the new name everywhere; do not keep aliases.
4. **Strip remnants** — Remove dead functions, unused config keys, obsolete comments, and docs that describe the old approach.
5. **Verify** — Run `./test/lint.sh` on touched scripts; run `./test/run-tests.sh` when `src/`, entrypoints, `configure.sh`, fixtures, or user-visible strings change.

## Remnants to remove

| Remnant | Instead |
|---------|---------|
| `oldFoo` / `newFoo` dual names | One name: `foo` (or the new canonical name) |
| Wrapper that only forwards to the new API | Call the new API directly |
| "Formerly X" / "Replaces Y" in docs | Describe current behaviour only |
| Deprecated alias env var or config key | Single key; update harness `test/docker/wsl-builds.conf` if applicable |
| Comment block explaining the old design | Delete; code should reflect the current design |
| Commented-out old implementation | Delete |

## wsl-builds touch points

When renaming or restructuring, check:

- `wsl-builder.sh`, `wsl-stacker.sh`, `configure.sh`
- `src/builder/install-dispatch.sh`, `src/stacker/`
- `builds/fixture-builder/`, `builds/fixture-review/`
- `test/docker/*.bats` — assertions on `printInfo`, prompts, usage text
- Root `README.md` Build List and affected `builds/<name>/README.md`
- `stacks/` and namespace READMEs when stack lines or build names change

## When to ask the user

Ask before proceeding only if the change likely affects **external** or **local user** state:

- `wsl-builds.conf` keys (gitignored user configs)
- CLI flags or positional args users may script against
- Stack file format or build-dir names referenced in user stacks outside the repo

Otherwise, proceed with a clean cut.
