# Automated Components Review

The automated review **does not install anything** and **is not a CI gate** unless the project chooses that later. For a given build directory and component, `./review/component-review.sh` runs `<slug>/audit.sh` (when present, under `builds/<build>/<slug>/`), validates **measurement-only** stdout, merges runner metadata and **runner-derived concerns**, persists `<slug>/review.result.json`, and prints a short acknowledgement.

## File layout

Each build keeps `conf.sh`, `install.sh`, and `README.md` at the build root. Per-component install and review files share `builds/<build>/<slug>/` (CSV hyphens → underscores in `slug`):

| Role | Path |
| ---- | ---- |
| Component install (sourced by dispatch) | `builds/<build>/<slug>/install.sh` |
| Audit script (measurement) | `builds/<build>/<slug>/audit.sh` |
| Maintainer manifest (maintainer-edited, machine-readable) | `builds/<build>/<slug>/audit.manifest.yaml` |
| Maintainer notes (human prose) | `builds/<build>/<slug>/audit.notes.md` |
| Persisted review result (runner-written) | `builds/<build>/<slug>/review.result.json` |

Maintainers edit `audit.manifest.yaml` and `audit.notes.md`; `component-review.sh` does not parse YAML or notes—it runs `audit.sh`, which reads the manifest when needed. Only `review.result.json` is written by the runner.

`<slug>` is the on-disk directory fragment (CSV hyphens → underscores), so token `mysql-client` uses `mysql_client/install.sh`, `mysql_client/audit.sh`, `mysql_client/audit.manifest.yaml`, `mysql_client/audit.notes.md`, and `mysql_client/review.result.json`.

## Facts vs policy

- **`Concerns`** (four booleans) on the persisted file are **measurement-aligned facts**, not verdict codes: **`security`**, **`freshness`**, **`skipped`**, **`incomplete`** (always present — see normative contract in [`docs/automated-builds-review-v1-spec.md`](../docs/automated-builds-review-v1-spec.md)). They are computed by **`component-review.sh`** from **`checks`** + **`required_check_ids`** + **`custom_issue_policy`** supplied on audit stdout — audits do not emit **`concerns`**.
- **`review_result`**, fixed phrase labels, **`summary`**, and **`reasons`** are **policy views**. They belong to a future **build-level** review step (planned **`build-review.sh`**), **not** to the component artefact.

Use the component output to spot **security-class issues**, **staleness/upstream drift**, **intentionally skipped checks**, **incomplete measurement stories**, and similar hygiene — **advisory** input for humans.

## Layout and main pieces

| Piece | Location | Role |
| ----- | -------- | ---- |
| Component review runner | `review/component-review.sh` | Invoke `<slug>/audit.sh`; validate audit stdout; merge `build`, `component`, `review_completed`; derive **`concerns`**; validate merged JSON; write `<slug>/review.result.json` on success. |
| Build review runner (planned) | `src/review/build-review.sh` | Walk `VALID_INSTALL_COMPONENTS` in CSV order; soft-skip when `<slug>/audit.sh` is missing; future build-level roll-up and exits. |
| Shared path / token helpers | `src/review/runner-common.sh` | Resolve repo root, map CSV token → `<slug>` (hyphens → underscores), paths to install / audit / manifest / result files. |
| Merged JSON validation | `src/review/merged-result-validation.sh` | Enforce audit measurement envelope; enforce persisted **`concerns`** shape and forbid verdict-only fields after merge. |
| Concerns derivation | `src/review/checks-rollup.sh`, `src/review/checks-rollup.jq` (`emitConcernsFromChecks`) | From **`checks`** + policy inputs → **`concerns`** object (runner only). |
| Reusable measurement modules | `src/review/audit-checks/*.sh` | One stdout line per run: single check JSON object with optional nested `evidence`. |
| Shared helpers | `src/review/audit-check-helpers/*.sh` | Bundling measurements, manifest scalars, HTTP fetch — **no** required stdout contract as a whole. |
| Per-component audit | `builds/<build>/<slug>/audit.sh` | Measurement only (`checks` with optional nested per-check `evidence`, `required_check_ids`, optional **`custom_issue_policy`**); reads `<slug>/audit.manifest.yaml` when needed (`component-review.sh` does not parse YAML). |

### Per-component `audit.sh` (repo root and catalogue paths)

Set `REPO_ROOT` to the git root of this repository and `export` it before sourcing `src/review/audit-check-helpers/`. For composition, prefer `audit-flow.sh` (`auditFlowInit`, `auditFlowRunModuleStem`, `auditFlowAppendSkippedFromModuleStem`, and related helpers) so catalogue modules resolve through `auditCheckModulePath` (unknown stems fail fast with a clear stderr message).

## `<slug>/audit.manifest.yaml` (maintainer manifest)

A **maintainer-edited, machine-readable** YAML file under `builds/<build>/<slug>/audit.manifest.yaml`, where `<slug>` is the same directory name as the per-component install path (hyphens in the CSV token become underscores). Keep it concise and scalar-oriented for values **`audit.sh`** reads directly. **`review.result.json`** is **runner-written** (last merged run); do not hand-edit that file.

### What maintainers should do

- Keep `component` correct and aligned with `conf.sh` / dispatch.
- Update `installer_validated` when you have **verified** the install path still matches reality (and adjust any thresholds your audit uses).
- Set `last_known_upstream` when you want **exact-match** (or related) checks to mean something concrete; leave empty if that check should **skip**.
- Add **component-specific** single-line scalars only when `<slug>/audit.sh` reads them (see pilot `shellcheck/audit.manifest.yaml`). Prefer simple `key: value` rows: helpers like `readManifestScalarLine` do not parse folded YAML blocks for machine fields.
- Keep longer rationale, reviewer prose, and check-story commentary in `<slug>/audit.notes.md` (not in the manifest YAML).

Full field list and types: [Maintainer manifest (v1 minimal shape)](../docs/automated-builds-review-v1-spec.md#maintainer-manifest-v1-minimal-shape).

### Keys (v1 minimal shape + common extensions)

| Key | Tier | Purpose |
| --- | ---- | ------- |
| `component` | Required | Canonical CSV token; must match review JSON `component`; file lives at `<slug>/audit.manifest.yaml`. |
| `upstream_tracking` | Recommended | Plain language: apt vs tarball vs API — **not** parsing rules (those stay in `<slug>/audit.sh`). |
| `last_known_upstream` | Optional | Maintainer-known upstream/deb string for drift checks (**interpretation** in the audit script). |
| `installer_validated` | Optional | `YYYY-MM-DD` (recommended): last time someone validated the installer approach. |
| `notes` | Optional | Short scalar note only; narrative prose belongs in `audit.notes.md`. |

**Extensions (examples):** audits may read additional **single-line** scalars — for example `installer_staleness_max_days`, `compare_cli_to_github_semver` — defined and documented **per component** in the manifest and `<slug>/audit.sh`, not by a global schema in v1.

## `<slug>/audit.notes.md` (human prose)

Use `builds/<build>/<slug>/audit.notes.md` for maintainer-facing narrative:

- Why checks are required or optional.
- Interpretation caveats (for example apt lag vs upstream GitHub tags).
- Expected concern behavior for fixture scenarios.
- Any longer rationale that would make YAML noisy or parser-hostile.

## Debug harness (`review/review-debug.sh`)

`review/review-debug.sh` is a maintainer-only helper for developing audits and audit-check modules. It does not modify the runner contract — it just shells out to existing pieces in isolation.

| Mode | What it does |
| ---- | ------------ |
| `run-check` | Run one `src/review/audit-checks/<name>.sh` module directly; derive `audit_check_id` from the module stem and pass it as argv[1], then append caller `--args`. |
| `run-audit` | Run one `builds/<build>/<slug>/audit.sh`, validate its measurement envelope, and print stdout. |
| `run-review` | Invoke `./review/component-review.sh <build> <component>` and print the persisted `<slug>/review.result.json`. |
| `run-e2e` | Convenience wrapper: run `run-audit` then `run-review`. Default `--build` is `review-fixture`. |

Output options:

- `--json` — print the relevant JSON payload (compact).
- `--pretty` — pretty-print the JSON payload through `jq .`.
- `--show-concerns` — also derive and print the runner-owned `concerns` object from the audit envelope (works in `run-audit` and `run-e2e`).

Examples:

```bash
./review/review-debug.sh --help
./review/review-debug.sh run-check  --module cli-reported-version --args 'no-such-cli-tool' --pretty
./review/review-debug.sh run-audit  --build review-fixture --component happy-path --pretty --show-concerns
./review/review-debug.sh run-review --build review-fixture --component issue-routed --pretty
./review/review-debug.sh run-e2e    --component policy-none-route --show-concerns --pretty
```

The harness exits non-zero on bad args, missing modules/audit scripts, or runner failures, and forwards the underlying exit code where applicable.

## Review fixture (`builds/review-fixture/`)

`builds/review-fixture/` provides deterministic offline scenarios for both the Docker Bats suite (`test/docker/review-fixture-tests.bats`) and the debug harness above. Each component token maps to one scenario whose `<slug>/audit.sh` emits a fixed, hand-written JSON line — no jq, helpers, or network — so the runner contract (envelope validation, `concerns` derivation, persisted artefact shape, no-overwrite-on-failure) can be exercised reliably.

See [`builds/review-fixture/README.md`](../builds/review-fixture/README.md) for the scenario table and expected `concerns` per token.

Normative contract: [Automated builds review (v1 spec)](../docs/automated-builds-review-v1-spec.md).
