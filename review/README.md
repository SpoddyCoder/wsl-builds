# Automated Components Review

Advisory, **non-installing**, **non-gating** review for build components...

```bash
./review/component-review.sh <build> <component>
```

...runs the component's `audit.sh` (when present), validates measurement-only stdout, derives `concerns`, and writes `builds/<build>/<component>/review.result.json`.

## Adding `audit.sh` to a component

### File layout


| Role                                                | Path                              |
| --------------------------------------------------- | --------------------------------- |
| Install                                             | `<component>/install.sh`          |
| Audit script                                        | `<component>/audit.sh`            |
| Maintainer manifest (you edit this)                 | `<component>/audit.manifest.yaml` |
| Persisted result (runner-written; do not hand-edit) | `<component>/review.result.json`  |


Pilot to copy from: `[builds/dev-bash/shellcheck/](../builds/dev-bash/shellcheck/)`.

### Terminology (canonical)

Use these terms consistently in review docs and scripts:

- `audit catalogue`: reusable scripts under `src/review/audit-checks/`.
- `check module`: one executable in the audit catalogue.
- `check module name`: module filename without `.sh` (for example `cli-reported-version`).
- `check_id`: stable per-check identifier in emitted JSON (`audit_check_id` field).
- `check module args`: positional args passed after `<check_id>` when invoking a module.
- Deprecated: `stem`. Keep it only in historical notes.

### Audit check modules


| Check module name               | What it measures                                                 | Check module args (after `<check_id>`)   | Outcomes                                                                                                           |
| ------------------------------- | ---------------------------------------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `cli-reported-version`          | Runs `<cli> --version` and extracts a version line.              | `<cli_command> [sed_extract_script]`     | `passed` (evidence: `cli_reported_version`, `cli_command_name`); `inconclusive` if CLI not on PATH.                |
| `deb-installed-version`         | Reads installed Debian package version via `dpkg-query`.         | `<deb_package_name>`                     | `passed` (evidence: `deb_installed_version`); `inconclusive` if not Debian or package not installed.               |
| `installer-validated-staleness` | Age of manifest `installer_validated` against a max-days policy. | `<YYYY-MM-DD> <max_age_days>`            | `passed`; `issue` (`finding_kind: staleness`); `skipped` if date empty; `inconclusive` for unparseable date.       |
| `http-json-upstream-version`    | HTTP GET (with retry) and jq-extract a value.                    | `<url> <jq_filter> [max_time_seconds]`   | `passed` (evidence: `http_json_extracted`); `inconclusive` on fetch or extract failure.                            |
| `upstream-exact-match`          | String equality (after trim) between expected and observed.      | `<expected> <observed>`                  | `passed`; `issue` (`finding_kind: upstream_drift`); `skipped` if expected empty; `inconclusive` if observed empty. |
| `upstream-semver-drift`         | Semver ordering via `sort -V` after optional leading `v` strip.  | `<observed_version> <reference_version>` | `passed`; `issue` (`finding_kind: upstream_drift`) if observed older; `inconclusive` if either operand empty.      |


Audit catalogue under `[src/review/audit-checks/](../src/review/audit-checks/)`. All check modules receive `<check_id>` as `argv[1]` (set automatically by `auditFlowRunCheckModuleName`), emit one JSON line on stdout, and use non-zero exit only for uncontrolled failures.

Need a check that is not in the catalogue? Add a new module under `[src/review/audit-checks/](../src/review/audit-checks/)` following the existing modules and the [v1 spec](../docs/automated-builds-review-v1-spec.md).

### `audit.manifest.yaml`

Maintainer-edited, machine-readable. Keep it concise and scalar-oriented — `readManifestScalarLine` handles plain top-level `key: value` lines only, not folded YAML blocks.


| Key                   | Tier        | Purpose                                                                         |
| --------------------- | ----------- | ------------------------------------------------------------------------------- |
| `component`           | Required    | Canonical CSV token; must match review JSON `component`.                        |
| `upstream_tracking`   | Recommended | Plain-language packaging summary (apt, tarball, API, …).                        |
| `last_known_upstream` | Optional    | Maintainer-known upstream/deb string for drift checks. Empty → check `skipped`. |
| `installer_validated` | Optional    | `YYYY-MM-DD` you last validated the install path. Empty → staleness `skipped`.  |
| `notes`               | Optional    | One-line maintainer note.                                                       |


Per-component policy overrides: add single-line scalars only when `audit.sh` reads them. Examples: `installer_staleness_max_days` (overrides `[review/review-policy.yaml](review-policy.yaml)` and the `resolveInstallerStalenessMaxDays` fallback), `compare_cli_to_github_semver`. Document each in the manifest beside the key.

Full schema: [Maintainer manifest (v1 minimal shape)](../docs/automated-builds-review-v1-spec.md#maintainer-manifest-v1-minimal-shape).

### `audit.sh` skeleton

`audit.sh` only **measures** — it does not install. Use `audit-flow.sh` so module orchestration stays declarative and reads as a check plan:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../src/common/bootstrap-common.sh"
resolveRepoRootFromAuditScript "${BASH_SOURCE[0]}" || exit 1
source "${REPO_ROOT}/src/review/audit-check-helpers/audit-flow.sh"
source "${REPO_ROOT}/src/review/audit-check-helpers/review-policy-defaults.sh"

manifest="${SCRIPT_DIR}/audit.manifest.yaml"
installer_validated=$(readManifestScalarLine "${manifest}" installer_validated)
installer_staleness_max_days=$(resolveInstallerStalenessMaxDays "${manifest}")

auditFlowInit 'mytool/audit.sh' '["cli-reported-version","installer-validated-staleness"]' || exit 1

auditFlowRunCheckModuleName cli-reported-version mytool || exit 1
auditFlowRunCheckModuleName installer-validated-staleness "${installer_validated}" "${installer_staleness_max_days}" || exit 1

auditFlowEmitMeasurementJson
```

Rules:

- Stdout: exactly one measurement-envelope JSON line (printed by `auditFlowEmitMeasurementJson`). Stderr: diagnostics only.
- Requires `jq`; the HTTP module also needs `curl`.
- Reuse evidence between modules with `auditFlowEvidenceField <check_id> <evidence_key>` (`<check_id>` maps to the `audit_check_id` JSON field).
- Record an intentional skip without invoking the check module via `auditFlowAppendSkippedFromCheckModuleName <check module name> "<reason>"`.
- The `required_check_ids` array passed to `auditFlowInit` lists `check_id` values whose absence or inconclusive outcome should mark the result `incomplete`.

### What you get back

`review.result.json` includes the audit `checks` array (with optional per-check `evidence`) plus a runner-derived `concerns` object with four booleans: `security`, `freshness`, `skipped`, `incomplete`. These are measurement-aligned facts (computed from `checks`, `required_check_ids`, and an optional `custom_issue_policy` you may emit), not pass/fail verdicts. Use them as advisory input for humans.

## Developing and Debugging

For developing audits and modules in isolation, use the maintainer debug harness:


| Mode         | What it does                                                                                                           |
| ------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `run-check`  | Run one `src/review/audit-checks/<name>.sh` directly; check module name becomes `check_id` (stored as `audit_check_id`), then your `--args` follow as check module args. |
| `run-audit`  | Run one `<slug>/audit.sh` and validate its measurement envelope.                                                       |
| `run-review` | Run `./review/component-review.sh` and print the persisted `review.result.json`.                                       |
| `run-e2e`    | `run-audit` then `run-review` (default `--build fixture-review`).                                                      |


Output flags: `--json` (compact), `--pretty` (`jq .`), `--show-concerns` (also derive the runner-owned `concerns`; works in `run-audit` and `run-e2e`).

```bash
./review/review-debug.sh --help
./review/review-debug.sh run-check  --module cli-reported-version --args 'no-such-cli-tool' --pretty
./review/review-debug.sh run-audit  --build fixture-review --component happy-path --pretty --show-concerns
./review/review-debug.sh run-review --build fixture-review --component issue-routed --pretty
./review/review-debug.sh run-e2e    --component policy-none-route --show-concerns --pretty
```

The harness exits non-zero on bad args, missing modules or audit scripts, and runner failures, forwarding the underlying exit code where applicable.

---

## Framework internals (maintainers)

Read this section if you change how the runner, validation, or `concerns` derivation work. Source of truth: `[docs/automated-builds-review-v1-spec.md](../docs/automated-builds-review-v1-spec.md)`.

### Layout


| Piece                         | Location                                                                                | Role                                                                                                                                                                     |
| ----------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Shared bootstrap, printing    | `src/common/bootstrap-common.sh`, `src/common/print.sh`                                 | Repo-root resolution and messaging; sourced before review libraries.                                                                                                     |
| Component review runner       | `review/component-review.sh`                                                            | Invoke `<slug>/audit.sh`; validate envelope; merge `build`, `component`, `review_completed`; derive `concerns`; validate merged JSON; write `<slug>/review.result.json`. |
| Build review runner (planned) | `review/build-review.sh`                                                                | Walk `VALID_INSTALL_COMPONENTS` in CSV order; build-level roll-up. Orchestrator implementation will live under `src/review/`.                                            |
| Path / token helpers          | `src/review/runner-common.sh`                                                           | Repo-root resolution, CSV token → `<slug>` mapping, install/audit/manifest/result paths.                                                                                 |
| Merged JSON validation        | `src/review/merged-result-validation.sh`                                                | Audit envelope shape; persisted `concerns` shape; forbid verdict-only fields after merge.                                                                                |
| Concerns derivation           | `src/review/checks-rollup.sh`, `src/review/checks-rollup.jq` (`emitConcernsFromChecks`) | `checks` plus policy → `concerns` (runner only).                                                                                                                         |
| Audit-check modules           | `src/review/audit-checks/*.sh`                                                          | Catalogue. One stdout JSON line per run; non-zero exit = uncontrolled failure.                                                                                           |
| Audit helpers                 | `src/review/audit-check-helpers/*.sh`                                                   | Composition (`audit-flow.sh`), HTTP fetch with retry, manifest scalars, repo policy resolution, module-path resolver. No stdout contract.                                |


### Facts vs policy

The persisted `concerns` object is a set of measurement-aligned facts. Verdict-shaped fields — `review_result`, fixed phrase labels, `summary`, `reasons` — belong to the future build-level review (`build-review.sh`), **not** to the component artefact. Audits emit `checks` plus `required_check_ids` plus optional `custom_issue_policy`; `component-review.sh` does the rest, and `merged-result-validation.sh` rejects verdict-only fields if any leak in.

### Repo-level policy

`[review/review-policy.yaml](review-policy.yaml)` holds repo defaults (flat `key: value`, same constraints as component manifests). Resolution order is **component manifest → `review/review-policy.yaml` → fallback constant** in `src/review/audit-check-helpers/review-policy-defaults.sh` (for example `resolveInstallerStalenessMaxDays`).

### Review fixture

`[builds/fixture-review/](../builds/fixture-review/)` provides deterministic offline scenarios for both the Docker Bats suite (`test/docker/review-fixture-tests.bats`) and the debug harness above. Each component's `audit.sh` emits a hand-written JSON line — no jq, helpers, or network — so envelope validation, `concerns` derivation, persisted artefact shape, and no-overwrite-on-failure can all be exercised reliably. Scenario table: `[builds/fixture-review/README.md](../builds/fixture-review/README.md)`.