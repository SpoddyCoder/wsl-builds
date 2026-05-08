# Automated Components Review

The automated review **does not install anything** and **is not a CI gate** unless the project chooses that later. For a given build directory and component, `src/review/component-review.sh` runs `<slug>_audit.sh` (when present), validates **measurement-only** stdout, merges runner metadata and **runner-derived concerns**, persists **`<slug>_review.result.json`**, and prints a short acknowledgement.

## Facts vs policy

- **`Concerns`** (four booleans) on the persisted file are **measurement-aligned facts**, not verdict codes: **`security`**, **`freshness`**, **`skipped`**, **`incomplete`** (always present — see normative contract in [`docs/automated-builds-review-v1-spec.md`](../docs/automated-builds-review-v1-spec.md)). They are computed by **`component-review.sh`** from **`checks`** + **`required_check_ids`** + **`custom_issue_policy`** supplied on audit stdout — audits do not emit **`concerns`**.
- **`review_result`**, fixed phrase labels, **`summary`**, and **`reasons`** are **policy views**. They belong to a future **build-level** review step (planned **`build-review.sh`**), **not** to the component artefact.

Use the component output to spot **security-class issues**, **staleness/upstream drift**, **intentionally skipped checks**, **incomplete measurement stories**, and similar hygiene — **advisory** input for humans.

## Layout and main pieces

| Piece | Location | Role |
| ----- | -------- | ---- |
| Component review runner | `src/review/component-review.sh` | Invoke `<slug>_audit.sh`; validate audit stdout; merge `build`, `component`, `review_completed`; derive **`concerns`**; validate merged JSON; write `<slug>_review.result.json` on success. |
| Build review runner (planned) | `src/review/build-review.sh` | Walk `VALID_INSTALL_COMPONENTS` in CSV order; soft-skip when `<slug>_audit.sh` is missing; future build-level roll-up and exits. |
| Shared path / token helpers | `src/review/runner-common.sh` | Resolve repo root, map CSV token → `<slug>` (hyphens → underscores), paths to install / audit / manifest / result files. |
| Merged JSON validation | `src/review/merged-result-validation.sh` | Enforce audit measurement envelope; enforce persisted **`concerns`** shape and forbid verdict-only fields after merge. |
| Concerns derivation | `src/review/checks-rollup.sh`, `src/review/checks-rollup.jq` (`emitConcernsFromChecks`) | From **`checks`** + policy inputs → **`concerns`** object (runner only). |
| Reusable measurement modules | `src/review/audit-checks/*.sh` | One stdout line per run: single check JSON object with optional nested `evidence`. |
| Shared helpers | `src/review/audit-check-helpers/*.sh` | Bundling measurements, manifest scalars, HTTP fetch — **no** required stdout contract as a whole. |
| Per-component audit | `builds/<build>/<slug>_audit.sh` | Measurement only (`checks` with optional nested per-check `evidence`, `required_check_ids`, optional **`custom_issue_policy`**); reads `<slug>_review.yaml` when needed (`component-review.sh` does not parse YAML). |

## `<slug>_review.yaml` (maintainer manifest)

A **human-owned** file beside `install_<slug>.sh`: `<slug>_review.yaml`, where `<slug>` matches the install/audit basename (hyphens in the CSV token become underscores). It holds **policy-friendly values** and **prose** for PR reviewers. `<slug>_review.result.json` is the **machine-written** last run; do not hand-edit that file.

### What maintainers should do

- Keep `component` correct and aligned with `conf.sh` / dispatch.
- Update `installer_validated` when you have **verified** the install path still matches reality (and adjust any thresholds your audit uses).
- Set `last_known_upstream` when you want **exact-match** (or related) checks to mean something concrete; leave empty if that check should **skip**.
- Use `upstream_tracking`, `aggregation_notes`, and `notes` so the next maintainer understands **how upstream is tracked**, **which checks are required**, and **what drives `concerns` / rollup intent**.
- Add **component-specific** single-line scalars only when `<slug>_audit.sh` reads them (see pilot `shellcheck_review.yaml`). Prefer simple `key: value` rows: helpers like `readManifestScalarLine` do not parse folded YAML blocks for machine fields.

Full field list and types: [Maintainer manifest (v1 minimal shape)](../docs/automated-builds-review-v1-spec.md#maintainer-manifest-v1-minimal-shape).

### Keys (v1 minimal shape + common extensions)

| Key | Tier | Purpose |
| --- | ---- | ------- |
| `component` | Required | Canonical CSV token; must match review JSON `component`; filename uses `<slug>_review.yaml`. |
| `upstream_tracking` | Recommended | Plain language: apt vs tarball vs API — **not** parsing rules (those stay in `<slug>_audit.sh`). |
| `aggregation_notes` | Recommended | Human summary: required check IDs, thresholds, what raises **`concerns`** — **not** version-string grammar. |
| `last_known_upstream` | Optional | Maintainer-known upstream/deb string for drift checks (**interpretation** in the audit script). |
| `installer_validated` | Optional | `YYYY-MM-DD` (recommended): last time someone validated the installer approach. |
| `notes` | Optional | Freeform context for reviewers. |

**Extensions (examples):** audits may read additional **single-line** scalars — for example `installer_staleness_max_days`, `compare_cli_to_github_semver` — defined and documented **per component** in the manifest and `<slug>_audit.sh`, not by a global schema in v1.

Normative contract: [Automated builds review (v1 spec)](../docs/automated-builds-review-v1-spec.md).
