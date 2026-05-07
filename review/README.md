# Automated Components Review

The automated review **does not install anything** and **is not a CI gate** unless the project chooses that later. For a given build directory and component, it runs `<slug>_audit.sh` (when present), which prints **one JSON object** describing measurements (`checks` / `evidence`) and a rolled-up `review_result` (0–3). The numeric code must agree with `review_result_label` (runner validation):

| `review_result` | `review_result_label` (v1 fixed string) |
| --------------- | --------------------------------------- |
| 0               | Checks ran; no issues found. |
| 1               | Checks ran; critical security or other major issue found. |
| 2               | Checks ran; very out of date. |
| 3               | Checks did not complete successfully (runner error, upstream unreachable, unsupported case, unknown). |

Use it to spot **stale validation**, **upstream drift**, **version / package signals**, and similar hygiene—**advisory** input for humans.

## Layout and main pieces

| Piece | Location | Role |
| ----- | -------- | ---- |
| Component review runner | `src/review/component-review.sh` | Invoke `<slug>_audit.sh`, merge runner fields, validate JSON, write `<slug>_review.result.json` on success. |
| Build review runner (planned) | `src/review/build-review.sh` | Walk `VALID_INSTALL_COMPONENTS` in CSV order; soft-skip when `<slug>_audit.sh` is missing. |
| Shared path / token helpers | `src/review/review-common.sh` | Resolve repo root, map CSV token → `<slug>` (hyphens → underscores), paths to install / audit / manifest / result files. |
| Merged JSON validation | `src/review/review-merged-validation.sh` | Enforce required top-level fields and `review_result` / `review_result_label` pairing after merge. |
| Aggregation | `src/review/review-aggregation.sh`, `src/review/review-aggregation.jq` | Turn `checks` + policy into `review_result`, `reasons`, `summary`. |
| Reusable measurement modules | `src/review/audit-checks/*.sh` | One stdout line per run: JSON envelope with `check` + `evidence` (CLI version, deb version, HTTP JSON upstream, semver drift, staleness, etc.). |
| Shared helpers | `src/review/audit-check-helpers/*.sh` | Bundling measurements, manifest scalars, HTTP fetch with retries—**no** required stdout contract as a whole. |
| Per-component audit | `builds/<build>/<slug>_audit.sh` | Composes checks + one aggregation step; reads `<slug>_review.yaml` when the component needs manifest fields (`component-review.sh` does not parse YAML). |

## `<slug>_review.yaml` (maintainer manifest)

A **human-owned** file beside `install_<slug>.sh`: `<slug>_review.yaml`, where `<slug>` matches the install/audit basename (hyphens in the CSV token become underscores). It holds **policy-friendly values** and **prose** for PR reviewers. `<slug>_review.result.json` is the **machine-written** last run; do not hand-edit that file.

### What maintainers should do

- Keep `component` correct and aligned with `conf.sh` / dispatch.
- Update `installer_validated` when you have **verified** the install path still matches reality (and adjust any thresholds your audit uses).
- Set `last_known_upstream` when you want **exact-match** (or related) checks to mean something concrete; leave empty if that check should **skip**.
- Use `upstream_tracking`, `aggregation_notes`, and `notes` so the next maintainer understands **how upstream is tracked**, **which checks are required**, and **what would change the rollup**.
- Add **component-specific** single-line scalars only when `<slug>_audit.sh` reads them (see pilot `shellcheck_review.yaml`). Prefer simple `key: value` rows: helpers like `reviewManifestScalar` do not parse folded YAML blocks for machine fields.

Full field list and types: [Maintainer manifest (v1 minimal shape)](../docs/automated-builds-review-v1-spec.md#maintainer-manifest-v1-minimal-shape).

### Keys (v1 minimal shape + common extensions)

| Key | Tier | Purpose |
| --- | ---- | ------- |
| `component` | Required | Canonical CSV token; must match review JSON `component`; filename uses `<slug>_review.yaml`. |
| `upstream_tracking` | Recommended | Plain language: apt vs tarball vs API—**not** parsing rules (those stay in `<slug>_audit.sh`). |
| `aggregation_notes` | Recommended | Human summary: required check IDs, thresholds, what drives `review_result` 1/2/3—**not** version-string grammar. |
| `last_known_upstream` | Optional | Maintainer-known upstream/deb string for drift/exact checks (**interpretation** in the audit script). |
| `installer_validated` | Optional | `YYYY-MM-DD` (recommended): last time someone validated the installer approach. |
| `notes` | Optional | Freeform context for reviewers. |

**Extensions (examples):** audits may read additional **single-line** scalars—e.g. `installer_staleness_max_days`, `compare_cli_to_github_semver`—defined and documented **per component** in the manifest and `<slug>_audit.sh`, not by a global schema in v1.
