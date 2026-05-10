# Automated builds review — v1 phased delivery plan

**Living document.** This file is shared memory across **sessions and agents**. It combines **stable phase intent** (what each delivery phase aims to do—change only after reviewer agreement) with **working state** (progress, todos, handoff). Canonical behaviour is defined only by [automated-builds-review-v1-spec.md](automated-builds-review-v1-spec.md).

---

## Current contract (authoritative)

Use this section as the implementation contract for ongoing work. If any later section conflicts, this section wins.

- `builds/<build>/<slug>/audit.sh` stdout is **measurement only**: `component_reviewer_version`, `checks` (with optional per-check `evidence`), `required_check_ids`, optional `custom_issue_policy`; top-level `evidence` is forbidden.
- `./review/component-review.sh` (implementation in `src/review/component-review-main.sh`) owns merge fields (`build`, `component`, `review_completed`) and derives `concerns` via `emitConcernsFromChecks`.
- Persisted `builds/<build>/<slug>/review.result.json` is facts-only: `checks` (with optional per-check `evidence`), `concerns` (`security`, `freshness`, `skipped`, `incomplete`) plus merge metadata; top-level `evidence` is forbidden.
- Persisted component artefacts **must not** include `review_result`, `review_result_label`, `review_concerns`, `summary`, or `reasons`.
- Build-layer policy views (`review_result`, labels, summary/reasons) are deferred to delivery phase 7 (`build-review.sh` scope).
- Legacy notes about prior `review_result`-in-component flow are historical context only and must not be used as implementation guidance.

### Legacy model status

The older per-component rollup model (`review_result`, `review_concerns`, `summary`, `reasons`) is obsolete for current implementation work. Keep historical rows for audit trail, but treat them as superseded unless explicitly reactivated by a new decision row.

---

## Working state — read and update each session

*Reviewers and agents should refresh this section at the start of work and revise it before handoff.*

| Field | Value |
| ----- | ----- |
| **Last updated** | 2026-05-10 — Per-component layout under `builds/<build>/<slug>/`: `install.sh` (dispatch), `audit.sh`, `audit.manifest.yaml`, `review.result.json`. Maintainer narrative lives in manifest scalars and `<slug>/audit.sh` comments (see spec). Build roots keep only `conf.sh`, top-level `install.sh`, `README.md`. `pathForInstallScript` / `pathForAuditScript` / `pathForMaintainerYaml` / `pathForReviewResultJson` in `src/review/runner-common.sh` align with `src/builder/install-dispatch.sh` (CSV hyphens → underscore directory names). |
| **Current focus** | **Paused** before [delivery phase 6 — Roll out](automated-builds-review-v1-delivery-plan.md#delivery-phase-6--roll-out-to-more-components-and-builds) for maintainer review of spec/plan and tooling. Maintainers can now develop new audits + audit-check modules against the fixture-review scenarios via `./review/review-debug.sh`. When phase 6 resumes: first scoped increment adds `<slug>/audit.sh` + `<slug>/audit.manifest.yaml` (and tracked `<slug>/review.result.json` when appropriate); pilot **`builds/dev-bash/`** / **`shellcheck`**. Maintainer-facing automated-review prose: [`review/README.md`](../review/README.md). |
| **Pilot build** | `builds/dev-bash/` |
| **Pilot component (CSV token)** | `shellcheck` |
| **Branch (human, after phase commit)** | *(optional repo branch name)* |

### Phase status summary

Use this row per delivery phase. **Statuses:** `Not started` · `In progress` · `Blocked` · `Done` (human has committed that phase on a branch).

| Delivery phase | Status | Note |
| ---------------- | ------ | ---- |
| 1 — Layout | Done | Directories + `.gitkeep` placeholders committed on reviewer branch |
| 2 — Runner + minimal audit | Done | All chunks (1–6) accepted and committed on reviewer branch; pilot path **`component-review.sh dev-bash shellcheck`** runs `shellcheck/audit.sh` (was `shellcheck_audit.sh` before the 2026-05-09 layout move) |
| 3 — Aggregation helper | Done | Historical: pilot called **`emitRollupFromChecks`**. **2026-05-08:** rollup verdicts removed; **`emitConcernsFromChecks`** (**`checks-rollup.jq`**) is **runner-owned** in **`component-review.sh`** after audit measurement stdout. |
| 4 — First audit-check + helpers | Done | Pilot composes **`cli-reported-version.sh`** + **`measurement-bundle.sh`**; concerns from **`emitConcernsFromChecks`** in **`component-review.sh`** ( **`checks-rollup.*`** ). |
| 5 — Pilot component complete | Done | Full pilot catalogue + manifest prose + **`httpGetWithRetry`** (**`audit-check-helpers/http-get-with-retry.sh`**) aligned with [Network and flake policy (v1)](automated-builds-review-v1-spec.md#network-and-flake-policy-v1). Post-restructure note: audit module output and helper shape now use direct check rows with nested per-check `evidence` (no top-level evidence merge). |
| 6 — Rollout | Not started | |
| 7 — `build-review.sh` | Not started | |

### Global outstanding (not tied to one phase)

Track follow-ups that do not fit a single phase checklist.

- [x] Record **Pilot build** and **Pilot component (CSV token)** in *Working state* before phase 2 work that adds `<slug>/audit.manifest.yaml`, `<slug>/audit.sh`, or ties Bats/fixtures to a concrete tree token (beyond ephemeral `builds/.bats-review.*` harness dirs). *(Done: `builds/dev-bash/`, token `shellcheck`.)*
- [x] Cover the runner against tracked tree fixtures (no longer purely ephemeral). *(Done 2026-05-08: `test/docker/review-fixture-tests.bats` (RF1–RF9) drives `./review/component-review.sh fixture-review <token>` against the new `builds/fixture-review/` scenarios.)*
- Optional follow-up: **`test/docker/review-tests.bats`** (**R1–R7**) still only exercises ephemeral `review_stub/audit.sh` stubs for raw runner-validation guards; **`test/docker/Dockerfile`** does not install **`shellcheck`**, so nothing in Docker Bats yet asserts **`./review/component-review.sh dev-bash shellcheck`** against the real pilot tree (image already includes **`curl`** + **`jq`**). The new RF suite covers the runner contract end-to-end against tracked tree artefacts; the dev-bash pilot still needs a separate Docker integration if/when the dev-bash audit's network surface is acceptable in CI.
- **`review-debug.sh` `--diff-expected` mode** — explicitly deferred from the [tests + debugging additions](tests-debugging-additions.md) plan. If a maintainer needs reproducible diffs against golden packets later, add a `--diff-expected` flag that compares the current `audit` envelope (or persisted artefact) against tracked goldens under `builds/fixture-review/`. Out of scope for the 2026-05-08 increment.
- **`readManifestScalarLine`** ( **`src/review/audit-check-helpers/read-manifest-scalar.sh`** ) only reads simple single-line **`key: value`** rows; folded blocks or structured YAML for machine fields would need a different approach.
- **Delivery phase 6 (pilot tidy-up):** Treat `builds/dev-bash/shellcheck/audit.sh` as exercising the full phase **5** **`audit-checks/`** catalogue; when rolling out phase **6**, drop **`upstream-exact-match`** and **`upstream-semver-drift`** (and **`http-json-upstream-version`** if nothing else in that audit needs the fetch) so the pilot matches **per-component composition**—only checks that really apply to apt-installed shellcheck. Sync `requiredCheckIdsJson`, `builds/dev-bash/shellcheck/audit.manifest.yaml`, and tracked `builds/dev-bash/shellcheck/review.result.json`.
- **Roadmap — build-level policy view (delivery phase 7 / spec `build-review.sh`):** Decide where the first **aggregate** output lives (file path vs stdout-only), its JSON shape, and how **`review_result`**, **`review_result_label`**, **`summary`**, and **`reasons`** apply **above** per-component artefacts. **Out of scope** for the component-only restructure in [`policy-views-resturcture.md`](policy-views-resturcture.md); track in spec Phase 2 / this plan when **`build-review.sh`** work starts.

### Open questions and blockers

- *(none — replace with dated bullets as needed)*

### Decisions and constraints log

Append rows when something is decided that **later phases must respect** (API names, file paths, policy, pilot choice, etc.).

| Date (ISO) | Decision or constraint |
| ---------- | ------------------------ |
| 2026-05-10 | **Dropped `audit.notes.md`:** per-component review artefacts are `audit.sh`, `audit.manifest.yaml`, and `review.result.json` only; longer maintainer context lives in manifest scalars (for example `upstream_tracking`, optional `notes`) and `<slug>/audit.sh` comments — see [Paths and filenames (v1)](automated-builds-review-v1-spec.md#paths-and-filenames-v1). |
| 2026-05-09 | **Review-only file layout moved into per-component subdirectories:** review files for a CSV token live under `builds/<build>/<slug>/` with **short basenames** — `audit.sh`, `audit.manifest.yaml`, `audit.notes.md`, `review.result.json` (e.g. `builds/dev-bash/shellcheck/audit.sh`). `<slug>` is still the on-disk fragment used by install dispatch (CSV hyphens → underscores). **Unchanged at the build root:** `conf.sh`, `install.sh`, `install_<slug>.sh`, `README.md`. **No changes** to `./wsl-builder.sh` or `src/builder/install-dispatch.sh`. `pathForAuditScript` / `pathForMaintainerYaml` / `pathForReviewResultJson` in `src/review/runner-common.sh` rewritten to emit the new paths; pilot `builds/dev-bash/shellcheck/` and all `builds/fixture-review/<slug>/` directories migrated; old flat `*_audit.sh` / `*_review.yaml` / `*_review.result.json` files deleted. Audit `_repo_root` resolution uses three `..` segments from `_script_dir` (one level deeper than before). `test/docker/review-tests.bats` ephemeral stubs now mkdir `<build>/review_stub/` and write `audit.sh` / `review.result.json` inside it. **No `component_reviewer_version` bump.** Rows below dated **2026-05-08** and earlier may reference older filenames as historical context. |
| 2026-05-08 | **Review fixture + debug harness landed:** new build `builds/fixture-review/` ships six deterministic offline scenarios (`happy-path`, `incomplete-required`, `issue-routed`, `policy-none-route`, `skipped-only`, `validation-fail`); each `<slug>_audit.sh` emits a hand-written one-line measurement envelope with no jq/network dependencies. Tracked `<slug>_review.result.json` exists for the five valid scenarios; `validation-fail` deliberately has no tracked result file (runner must not create one). New maintainer harness `./review/review-debug.sh` exposes `check`/`audit`/`component`/`scenario` modes with `--json` / `--pretty` / `--show-concerns`; default `--build` for `scenario` is `fixture-review`. New Bats suite `test/docker/review-fixture-tests.bats` (RF1–RF9) wired into `test/docker/run-bats.sh` after `review-tests.bats`. `validateAuditMeasurementJson` / `validateMergedResultJson` switched from `trap '... ${jq_err}' RETURN` to explicit `rm -f` cleanup before each `return` (the RETURN trap leaked `jq_err` across function frames once the validators were called from inside another function such as `runAuditMode`); same external behaviour. **No** spec contract change; persisted artefact stays facts-only. **No `component_reviewer_version` bump.** |
| 2026-05-08 | **Evidence relocation implemented (contract + code):** top-level `evidence` removed from audit stdout and persisted component artefacts; optional `evidence` now nests on each `checks[]` row only. `audit-checks/*.sh` emit a single check object; `measurement-bundle.sh` now appends check rows; validators explicitly reject top-level `evidence`; shellcheck pilot and review Bats updated. **No `component_reviewer_version` bump.** |
| 2026-05-08 | **Policy views restructure implemented (code + spec):** Per [`policy-views-resturcture.md`](policy-views-resturcture.md)—**`<slug>_audit.sh`** stdout is **measurement only** (`checks` with optional per-check `evidence`, `required_check_ids`, optional `custom_issue_policy`); **`component-review.sh`** merges runner fields, runs **`emitConcernsFromChecks`**, persists **`concerns`** with keys `security`, `freshness`, `skipped`, `incomplete`; **no** `review_result` / `summary` / `reasons` on **`<slug>_review.result.json`**. **No `component_reviewer_version` bump.** Rows dated **2026-05-07** below are **historical** (prior single-file rollup). |
| 2026-05-07 | **Library rename (implementers):** Dropped redundant `review-` prefix on shared **`src/review/`** filenames and **`camelCase`** helpers (aggregation **`emitRollupFromChecks`** + **`checks-rollup.jq`**, HTTP **`httpGetWithRetry`**, manifest **`readManifestScalarLine`**, merged JSON **`validateMergedResultJson`**, path helpers **`pathFor*`**, **`exportRepoRootFromRunnerPath`**, **`RUNNER_BASENAME`**, etc.). Canonical mapping: [`review-rename-task.md`](review-rename-task.md). **JSON artefacts and `review_*` result fields unchanged.** Rows below retain historical identifiers where useful. |
| 2026-05-07 | **Check `audit_check_id` names (pilot and rollout default):** use the **check module name** — basename of `src/review/audit-checks/<name>.sh` without `.sh` (e.g. `cli-reported-version`). When the same module runs **twice** in one audit, use **`<check-module-name>_<suffix>`** (e.g. `cli-reported-version_shellcheck`). Compose scripts derive names with **`auditCheckIdFromModulePath`** in **`src/review/audit-check-helpers/get-audit-check-id.sh`**. Historical note: legacy term `stem` in older symbols/prose is deprecated. |
| 2026-05-07 | **Historical (superseded by 2026-05-08 restructure):** prior per-component rollup contract used **`review_result`** 0–2 with **`review_concerns`** and fixed labels. Retained only as migration context; do not implement from this row. |
| 2026-05-07 | **Maintainer docs** for the automated review: [`review/README.md`](../review/README.md) — overview, layout under `src/review/`, **`<slug>_review.yaml`** maintainer duties and keys. **Spec** ([automated-builds-review-v1-spec.md](automated-builds-review-v1-spec.md)) and **delivery plan** (this file) point **maintainer-facing** prose there; canonical behaviour remains the spec. |
| 2026-05-07 | Per-component **review builder files** in `builds/<build>/`: **`<slug>_audit.sh`**, **`<slug>_review.yaml`**, **`<slug>_review.result.json`** (same **`<slug>`** as **`install_<slug>.sh`**). **`src/review/runner-common.sh`** path helpers; install scripts stay **`install_<slug>.sh`** until a separate rename project. Pilot: **`shellcheck_audit.sh`**, **`shellcheck_review.yaml`**, **`shellcheck_review.result.json`**. |
| 2026-05-07 | **Historical (superseded by 2026-05-08 restructure):** result JSON once required **`review_result_label`** and **`review_concerns`**. Current contract persists four-key **`concerns`** and forbids policy-view fields on component artefacts. |
| 2026-05-06 | v1 review **directory layout** under `src/review/`: `audit-checks/` and `audit-check-helpers/` are tracked in Git using **empty `.gitkeep` files** (one per subdirectory). No other empty-dir convention existed in the repo beforehand. |
| 2026-05-06 | **`build-review.sh`** lands in delivery phase **7** only. **`component-review.sh`** is introduced in delivery phase **2** (after phase 1 layout); phase 1 did not imply runnable review commands or audit coverage. |
| 2026-05-06 | Shared review **primitives** live in **`src/review/review-common.sh`** (sourced by **`component-review.sh`**). **camelCase** helpers: `reviewInitRepoRootFromRunnerScript`, `canonicalCsvTokenToOnDiskSlug`, `reviewPathForInstallScript`, `reviewPathForAuditScript`, `reviewPathForReviewManifest`, `reviewPathForReviewResult`, `reviewDefaultBuildsDirUnderRepo`. **Slug** = `${token//-/_}` (same as `install-dispatch.sh`). **`REPO_ROOT`**: caller passes runner **`BASH_SOURCE[0]`**; resolution assumes the runner lives under **`src/review/`** (repo root = two levels up from script dir). *(Superseded for manifest/result paths: 2026-05-07 — **`review_*` filenames now use **`<slug>`** with hyphens mapped to underscores; see newer decision row.)* |
| 2026-05-06 | **`BUILDS_ROOT`** / **`EXTERNAL_BUILDS_ROOT`** — **`resolveBuildsRootFromRepoRoot`** in **`src/builder/builds-root.sh`** is the single implementation; **`./wsl-builder.sh`** and **`./review/component-review.sh`** source **`src/common/print.sh`**, user **`wsl-builds.conf`**, then **`src/builder/builds-root.sh`** (same messages and semantics). **`reviewDefaultBuildsDirUnderRepo`** is only `${repoRoot}/builds` without reading config. Future **`./review/build-review.sh`** (delivery phase 7) should reuse **`resolveBuildsRootFromRepoRoot`** the same way. |
| 2026-05-06 | **component-review.sh** (chunk 2, reviewer-accepted): stable CLI — `./review/component-review.sh` then build directory name then canonical CSV token (same build name as `./wsl-builder.sh` first argument). Sources `runner-common.sh` / related `src/review/` libraries, `src/common/print.sh`, user `wsl-builds.conf`, `src/builder/builds-root.sh`; runs `bash` on `<slug>_audit.sh`; forwards audit stderr; requires exactly one stdout JSON line; merges `build`, `component`, `review_completed` (UTC ending `Z`); validates merged JSON with `jq`; on success persists **`<slug>_review.result.json`** (chunk 4 — **`${result_path}.tmp.$$`** then **`mv -f`**). `jq` documented in `CONTRIBUTING.md`. |
| 2026-05-06 | **Merged-json validation** (chunk 3): implementation in **`src/review/merged-result-validation.sh`** — source after **`src/common/print.sh`** and **`jq`** check; **`validateMergedResultJson`**, **`printMergedValidationFailure`**. **`component-review.sh`** calls **`validateMergedResultJson`** on the **merged** document only. **Docker Bats:** **`test/docker/review-tests.bats`** with stable ids **R1–R5** (chunk 4 adds **R5** overwrite-on-success); **`test/docker/run-bats.sh`** runs builder → review → wizard → commands; test image **`jq`** via **`test/docker/Dockerfile`**. **`test/README.md`** documents the Review catalog. *(**R3b**, **R6**, **R7** added 2026-05-07 — three-state rollup, **`review_concerns`**, aggregation helpers.)* |
| 2026-05-06 | **Result file persistence** (chunk 4, reviewer-accepted): **`component-review.sh`** writes only after **`validateMergedResultJson`** succeeds. Target path from **`pathForReviewResultJson "${BUILD_DIR}" "${canonical_token}"`** (`builds/<build>/<slug>/review.result.json`). **Atomic replace:** write **`merged_json`** to **`${result_path}.tmp.$$`**, then **`mv -f`** to **`${result_path}`**. Validation failure still **must not** create or overwrite the result file. |
| 2026-05-06 | **Pilot (phase 2):** **`builds/dev-bash/`** + canonical CSV token **`shellcheck`**. Maintainer manifest **`builds/dev-bash/shellcheck_review.yaml`** (chunk 5). Tree audit path **`builds/dev-bash/shellcheck_audit.sh`** (slug `shellcheck` → no hyphen change). Result artefact **`builds/dev-bash/shellcheck_review.result.json`** when **`component-review.sh`** succeeds. |
| 2026-05-06 | **`builds/dev-bash/shellcheck_audit.sh`** (chunk 6, committed): builds stdout JSON with **`jq`** (same **`jq`** prerequisite as **`component-review.sh`**; no install from audit scripts). Single measurement check **`audit_check_id` `shellcheck_cli`**, with then-current inline rollup logic (historical only; replaced by 2026-05-08 facts-only restructure). **`component-review.sh`** still does **not** read **`shellcheck_review.yaml`**. |
| 2026-05-06 | **Aggregation helper (delivery phase 3 chunk 1):** **`reviewAggregateFromChecks`** in **`src/review/review-aggregation.sh`**; jq program **`src/review/review-aggregation.jq`** (same directory, path resolved at **`review-aggregation.sh`** source time via **`dirname "${BASH_SOURCE[0]}"`**). **Arguments:** (1) **`checks`** JSON array, (2) **`required_check_ids`** JSON array of strings, (3) optional **`custom_issue_policy`** JSON — omit third argument or pass empty string for **`{}`**. Optional policy key **`routes_by_audit_check_id`:** maps check **`audit_check_id`** → **`"security"`**, **`"freshness"`**, or **`"none"`** for **`issue`** rows that are not classified by **`finding_kind`** alone ( **`custom`** or missing—see current spec). *(Historical note: this row once said **"1"** / **"2"**; **2026-05-07** standardizes on **`security`** / **`freshness`**.)* **Bash:** do **not** default the third argument with **`${3:-{}}`** (when **`$3`** is **`{}`**, expansion breaks **`jq`** **`--argjson`**); use **`[ -z "${custom_policy_json}" ]`** then **`custom_policy_json='{}'`**. |
| 2026-05-06 | **Pilot audit → aggregation helper (delivery phase 3 chunk 2):** **`builds/dev-bash/shellcheck_audit.sh`** sources **`"${repoRoot}/src/review/review-aggregation.sh"`** with **`repoRoot`** from **`$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)`**. Measurement unchanged (**`checks`** / **`evidence`**); **`emitFinalJson`** merges **`reviewAggregateFromChecks`** output into the finished document. Required IDs passed as JSON array (script uses **`readonly requiredCheckIdsJson='["shellcheck_cli"]'`** — **do not** name a top-level **`readonly required_ids_json`**: it collides with **`local required_ids_json`** inside **`reviewAggregateFromChecks`** and Bash errors **`readonly variable`**). Rollup **`summary`** / **`reasons`** / **`review_concerns`** follow **`review-aggregation.jq`** ( **`review_result` 0–2** ); required check **`inconclusive`** or unrouted **`issue`** ⇒ **`review_result` `2`**; clean pass ⇒ **`0`**. **`shellcheck_review.yaml`** **`aggregation_notes`** updated to mention helper. |
| 2026-05-06 | **Historical (superseded by 2026-05-08 evidence relocation):** first `audit-checks/` module rollout details. The module still exists, but output contract is now a single check object with optional nested `evidence` (not `{check,evidence}`). |
| 2026-05-06 | **Historical (superseded by 2026-05-08 evidence relocation):** **`audit-check-helpers` measurement bundles (delivery phase 4 chunk 2):** previous helper contract used `{checks,evidence}` bundles and shallow top-level evidence merge. Retained as migration context only; do not implement from this row. |
| 2026-05-06 | **Historical (superseded by 2026-05-08 evidence relocation):** **Pilot audit composition (delivery phase 4 chunk 3):** older notes reference top-level evidence bundle merges; keep for audit trail only. |
| 2026-05-06 | **Historical (superseded by 2026-05-08 evidence relocation):** pilot full catalogue compose notes from pre-relocation helper wiring. Keep for migration context only. |
| 2026-05-06 | **Pilot manifest policy prose (delivery phase 5 chunk 2):** **`builds/dev-bash/shellcheck_review.yaml`** **`upstream_tracking`** and **`aggregation_notes`** document shipped behaviour: apt/dpkg vs GitHub API measurement; **`requiredCheckIdsJson`** and empty third arg to **`reviewAggregateFromChecks`**; **`review-aggregation.jq`** treats required **`inconclusive`** (not **`skipped`**) as driving **`review_result` `2`**; **`shellcheck_github_release`** not required; semver check gated by **`compare_cli_to_github_semver`**; empty **`last_known_upstream`** ⇒ **`upstream_deb_exact`** **`skipped`**; **`installer_staleness`** = age of **`installer_validated`** vs **`installer_staleness_max_days`**. **`component-review.sh`** still does not parse YAML—the manifest is maintainer-edited and machine-readable (audits read it); only **`review.result.json`** is runner-written. |
| 2026-05-06 | **HTTP fetch retries/timeouts (delivery phase 5 chunk 3):** **`reviewHttpGetWithRetry`** in **`src/review/audit-check-helpers/review-http-fetch.sh`** follows [Network and flake policy (v1)](automated-builds-review-v1-spec.md#network-and-flake-policy-v1): up to **3** attempts, incremental short backoff (**1**s then **+1**s per further wait), retry only **HTTP 5xx** or **`curl` `%{http_code}` `000`** (no status / transport failure—timeouts, resets, connection failure), **no** **4xx** retries; **`curl --max-time`** default **30**s per attempt unless the caller passes the helper’s optional second argument; **`http-json-upstream-version.sh`** optional 4th arg is per-check **`max_time`**. Canonical prose: spec subsection **Shared helper behaviour (v1, `reviewHttpGetWithRetry`)**; helper header comments point there. |

---

## How agents and reviewers use this document

- **Read** *Working state* and the **Reference** block for the active delivery phase before implementing.
- **Do not commit or push** — only the human reviewer records Git history, after a full delivery phase is accepted (see [Per-chunk workflow](#per-chunk-workflow-human--agent)).
- **Check off** items under *Chunk checklist* when the **human reviewer** has accepted that chunk (not when the agent merely finished typing).
- **Append** under *Handoff notes for later phases* when something should survive across sessions (API quirks, file locations, partial work, “do not rely on X yet”). Prefer **ISO date + short headline** per entry, **newest first**.
- **Update** *Phase status summary*, *Current focus*, *Last updated*, and *Decisions log* whenever status or shared truth changes.
- **Resolve conflicts by precedence:** **Current contract (authoritative)** → spec → phase details/handoff history.
- **Prefer** [`review/README.md`](../review/README.md) for new **maintainer-facing** explanations of the automated review (layout, manifests, how to run); keep the **spec** normative—link and summarize in the README rather than forking behaviour docs.
- **Add** rows to *Decisions log* for any choice that future agents would otherwise rediscover only by accident.
- **Move or duplicate** todos into *Global outstanding* when they span phases or ownership is unclear.

---

## How this relates to spec “Phase 1 / Phase 2”

The spec’s rollout labels mean:

| Spec label | Scripts |
| ---------- | ------- |
| Spec Phase 1 (ship first) | `./review/component-review.sh` — one build + one CSV token; stable CLI for later orchestration |
| Spec Phase 2 (follows) | `./review/build-review.sh` — full build review loop (implementation under `src/review/` when shipped) |

**This delivery plan** uses **numbered delivery phases 1–7** below. **Delivery phase 7** corresponds to **spec Phase 2** (`build-review.sh`). **Delivery phases 1–6** implement **spec Phase 1** and grow coverage until the component path is proven end-to-end.

## Per-chunk workflow (human + agent)

**Git:** Agents **must not** commit, push, or otherwise write project history (`git commit`, merges, branching that records milestones, force-push, etc.) at **any** stage. Only the human reviewer records changes in Git. When the reviewer has accepted **all** work for a **delivery phase**, they **commit** that phase’s changes on a **new project branch**, then continue with the next phase (or merge via their usual process).

Each **reviewable chunk** within a phase should follow the same loop:

1. **Align on scope** — Reviewer and agent agree what is in/out, misreads of the spec, and implementation details **before** coding.
2. **Instruct implementation** — Agent (or human) implements only that scope.
3. **Review the implementation** — Diff, behaviour, and fit to spec.
4. **Request changes** — Update implementation, **or** update this plan or the spec if reality or requirements shifted.
5. **Repeat steps 3–4** until the reviewer accepts the chunk.
6. **Advance within the phase** — If further chunks remain in this delivery phase, update this document’s checklists/handoff notes, then return to step 1.
7. **Close out the phase (human only)** — When every chunk for this delivery phase is accepted, the reviewer commits the accumulated changes on a new branch before starting the **next** delivery phase.

Optional but high value for each chunk:

- **Definition of done** — Short bullet list: files touched, behaviours added, explicit non-goals (“does not yet …”).
- **Spec traceability** — Note which spec sections apply (headings in [automated-builds-review-v1-spec.md](automated-builds-review-v1-spec.md)), so review stays concrete.

## Cross-cutting checklist (when relevant)

Apply when a chunk touches runners, audits, or user-facing messages:

- **Host tools** — Anything required at runtime (`jq`, YAML parser, `curl`, …) must be listed in `CONTRIBUTING.md` when that code ships; scripts **must not** install dependencies. See [Review tooling dependencies (v1)](automated-builds-review-v1-spec.md#review-tooling-dependencies-v1).
- **Maintainer docs** — Explanations of what the automated review does, how to run it, manifest keys, and layout: [`review/README.md`](../review/README.md) (not root `README.md`). Spec remains normative; link from prose docs rather than duplicating the full contract.
- **Validation and artefacts** — On invalid JSON or failed validation, the runner **must not** create or overwrite `<slug>/review.result.json`. See [Runner validation (Phase 1)](automated-builds-review-v1-spec.md#runner-validation-phase-1) and [Persisted artefact validation (merged JSON)](automated-builds-review-v1-spec.md#persisted-artefact-validation-merged-json).
- **Tests** — If behaviour, prompts, or wiring near `./wsl-builder.sh` / install paths changes in ways covered by the harness, update Bats/fixtures and run `./test/run-tests.sh` per [test/README.md](../test/README.md).
- **Builder + review shared code** — Behaviour needed by both **the builder** and **review runners** lives under **`src/`** (not only `src/review/`). Reuse **`src/common/print.sh`** and existing patterns instead of parallel stderr-only copies. **`resolveBuildsRootFromRepoRoot`** (**`src/builder/builds-root.sh`**) is the canonical **`BUILDS_ROOT`** resolver after user conf is sourced.

---

## Delivery phase 1 — Layout (directories and placeholders)

### Reference (change only after reviewer agreement)

**Goal:** Establish `src/review/` tree so later PRs have a stable home without landing all behaviour at once.

**Reviewable chunks:**

- Create target directories (and optional placeholder notes if the repo convention expects non-empty dirs): e.g. `src/review/`, `src/review/audit-checks/`, `src/review/audit-check-helpers/`, per [Audit helper library](automated-builds-review-v1-spec.md#audit-helper-library-shared-measurement) / layout in the spec.

**Definition of done:**

- Paths match the spec’s v1 target layout; no false claims in docs that runners already work unless they do.

**Spec refs:** [Paths and filenames (v1)](automated-builds-review-v1-spec.md#paths-and-filenames-v1) (or equivalent section in full spec), layout under audit helper library.

### Chunk checklist

- [x] Directories (`src/review/`, `audit-checks/`, `audit-check-helpers/`) exist per spec layout

### Handoff notes for later phases

- **2026-05-06 — Phase 1 layout committed**
  - Tree: `src/review/audit-checks/.gitkeep`, `src/review/audit-check-helpers/.gitkeep` (parent `src/review/` implied; no file at `src/review/` root).
  - Spec layout refs: [Audit helper library](automated-builds-review-v1-spec.md#audit-helper-library-shared-measurement), [Paths and filenames (v1)](automated-builds-review-v1-spec.md#paths-and-filenames-v1).
  - Runners and pilot artefacts are **out of scope** for this phase; next is **delivery phase 2** (shared primitives → `component-review.sh` → …).

### Outstanding for this phase

*(None.)*

---

## Delivery phase 2 — Component review runner + minimal audit path

### Reference

**Goal:** Shippable **spec Phase 1** vertical slice: one invokable `component-review.sh` that can run a real `<slug>/audit.sh`, validate **measurement stdout**, merge runner fields, derive runner-owned **`concerns`**, validate merged facts JSON, and persist `<slug>/review.result.json` on success.

**Validation and persistence target:** **Validation** and **persistence** apply to the **merged JSON** (stdout from the audit parsed as one object, plus runner-supplied fields and runner-derived `concerns`)—**not** to raw stdout alone. See [Runner validation (Phase 1)](automated-builds-review-v1-spec.md#runner-validation-phase-1).

**Why combined:** The runner’s contract is to **invoke** an audit and **validate** the **merged** result document. Without at least one audit that prints a valid measurement object, the runner cannot be exercised truthfully. Treat **runner + minimal audit + manifest** as one delivery phase, split into **multiple chunks** if needed, but do not leave “runner-only” in a state that nothing can run.

**Reviewable chunks (suggested order):**

1. **Shared primitives** — Sourcing strategy, token ↔ on-disk path helpers (`pathForInstallScript`, `pathForAuditScript`, …) (align with [Component enumeration](automated-builds-review-v1-spec.md#component-enumeration-v1-dispatch-aligned) / terminology).
2. **`component-review.sh` skeleton** — CLI: build dir + canonical CSV token; locate `<slug>/audit.sh`; invoke; capture one logical line of JSON from stdout; stderr = diagnostics only; merge runner fields into the parsed object before the validation step.
3. **Runner validation** — On audit stdout enforce measurement envelope contract; on merged JSON enforce required persisted facts shape (`concerns` keys/booleans, forbidden policy-view fields); on failure, exit non-zero and **do not** write or overwrite the result file.
4. **Persist artefact** — Write the **validated merged** JSON to `builds/<build>/<slug>/review.result.json` when appropriate.
5. **Maintainer manifest** — Add `<slug>/audit.manifest.yaml` for the pilot component with required/recommended fields per [Maintainer manifest (v1 minimal shape)](automated-builds-review-v1-spec.md#maintainer-manifest-v1-minimal-shape).
6. **Minimal `<slug>/audit.sh`** — Prints one valid **measurement** JSON object on stdout, exit 0; may use **no** `audit-checks/` yet (measurement inlined or empty `checks` with explicit required IDs/policy inputs). Must satisfy [Audit measurement stdout (Phase 1)](automated-builds-review-v1-spec.md#audit-measurement-stdout-phase-1) and merged artefact rules in [Review result JSON (component artefact, v1)](automated-builds-review-v1-spec.md#review-result-json-component-artifact-v1).

**Definition of done:**

- A maintainer can run `component-review.sh` for **one** chosen build + token and get either a persisted valid **merged** result file or a clear non-zero failure with no clobber of an existing bad file (validation runs after merge, per spec).
- Pilot `<slug>/audit.sh` may inline measurement composition through this phase; `concerns` derivation remains runner-owned in `component-review.sh`.
- `CONTRIBUTING.md` lists host tools once this path actually depends on them.

**Spec refs:** [Paths and filenames (v1)](automated-builds-review-v1-spec.md#paths-and-filenames-v1), [Process exit codes vs structured state](automated-builds-review-v1-spec.md#process-exit-codes-vs-structured-state), [Runner validation (Phase 1)](automated-builds-review-v1-spec.md#runner-validation-phase-1), [Audit measurement stdout (Phase 1)](automated-builds-review-v1-spec.md#audit-measurement-stdout-phase-1), [Review result JSON (component artefact, v1)](automated-builds-review-v1-spec.md#review-result-json-component-artifact-v1).

### Chunk checklist

- [x] 1 — Shared primitives (sourcing, token ↔ filename mapping)
- [x] 2 — `component-review.sh` skeleton (invoke audit, capture stdout, merge runner fields)
- [x] 3 — Runner validation on audit + merged JSON (measurement envelope, `concerns` shape, no overwrite on failure)
- [x] 4 — Persist validated **merged** `<slug>/review.result.json`
- [x] 5 — Pilot `<slug>/audit.manifest.yaml`
- [x] 6 — Minimal `<slug>/audit.sh` (valid measurement JSON on stdout, exit 0; historical row may reference pre-restructure rollup terms)

### Handoff notes for later phases

- **2026-05-06 — Chunk 6 `shellcheck_audit.sh`; delivery phase 2 complete (reviewer commit)**
  - **File:** `builds/dev-bash/shellcheck_audit.sh` — one logical line of JSON on stdout, **`exit 0`** on controlled path; stderr only for diagnostics / missing **`jq`** when run standalone.
  - **End-to-end verify:** `./review/component-review.sh dev-bash shellcheck` (writes **`shellcheck_review.result.json`** on merged validation success; spec [Runner validation (Phase 1)](automated-builds-review-v1-spec.md#runner-validation-phase-1)).
  - **Aggregation:** was inlined through phase **2** end; **delivery phase 3** switched **`shellcheck_audit.sh`** to **`reviewAggregateFromChecks`** (see phase **3** handoff, newest entry).
  - **Bats:** **R1–R5** remain on ephemeral **`builds/.bats-review.*`** + **`review_stub_audit.sh`**. Optional follow-up if desired: Dockerfile **`shellcheck`** + test hitting real pilot path (see *Global outstanding*).
- **2026-05-06 — Chunk 5 pilot `shellcheck_review.yaml` accepted (reviewer commit)**
  - **File:** `builds/dev-bash/shellcheck_review.yaml` — required `component: shellcheck`; recommended `upstream_tracking`, `aggregation_notes`; optional `notes`. Spec: [Maintainer manifest (v1 minimal shape)](automated-builds-review-v1-spec.md#maintainer-manifest-v1-minimal-shape), [Paths and filenames (v1)](automated-builds-review-v1-spec.md#paths-and-filenames-v1).
  - **Pilot:** *Working state* — **`builds/dev-bash/`**, token **`shellcheck`**. **`component-review.sh`** does not yet load the YAML (human/docs artefact for v1).
  - **Verify:** `cat builds/dev-bash/shellcheck_review.yaml`. **`./review/component-review.sh dev-bash shellcheck`** exercises **`shellcheck_audit.sh`** (chunk 6 handoff above).
- **2026-05-06 — Chunk 4 persist validated merged `<slug>_review.result.json` accepted (reviewer commit)**
  - **`component-review.sh`:** after **`validateMergedResultJson`**, writes **`merged_json`** to **`${result_path}`** (**`result_path`** from **`pathForReviewResultJson`**) using **`${result_path}.tmp.$$`** + **`mv -f`**; no write on validation or earlier failures.
  - **Tests / docs:** **`test/docker/review-tests.bats`** — **R1** asserts persisted file and key merged fields; **R5** successful run replaces an existing result file; **R4** unchanged (failure does not clobber); **R6** concern invariants. **`test/README.md`** Review catalog lists **R1–R6**.
  - **Superseded:** phase 2 complete; **`shellcheck_audit.sh`** landed in chunk 6 (see newest handoff entries above).
- **2026-05-06 — Chunk 3 runner validation on merged JSON accepted (reviewer commit)**
  - **Shipped:** **`src/review/merged-result-validation.sh`** (jq program unchanged from chunk 2 inline logic); **`component-review.sh`** sources it and calls **`validateMergedResultJson`** after merge.
  - **Tests:** **`test/docker/review-tests.bats`** — stable ids **R1** (happy path + merged runner fields), **R2** (missing `reasons`), **R3** (`review_result` out of range), **R4** (validation failure does not overwrite existing **`<slug>_review.result.json`**), **R6** (concern invariants). Ephemeral build dirs under **`builds/.bats-review.XXXXXX`** + token **`review-stub`** / **`review_stub_audit.sh`** (not a tree pilot).
  - **Docker:** **`jq`** added to **`test/docker/Dockerfile`**; **`test/docker/run-bats.sh`** runs **`review-tests.bats`** after **`builder-tests.bats`**. Verify with **`./test/run-tests.sh`**.
- **2026-05-06 — Chunk 2 `component-review.sh` + `builds-root` accepted (reviewer commit)**
  - **Shipped:** `review/component-review.sh` (today’s thin CLI + `src/review/component-review-main.sh`), `src/builder/builds-root.sh` (**`resolveBuildsRootFromRepoRoot`**), `wsl-builder.sh` delegates **`BUILDS_ROOT`** to that helper; `src/review/runner-common.sh` path helpers; **`CONTRIBUTING.md`** lists **`jq`** for review.
  - **Stable CLI:** `./review/component-review.sh` `<build-directory-name>` `<canonical-csv-token>` — **`BUILD_DIR`** = **`${BUILDS_ROOT}/`** first arg; **`BUILDS_ROOT`** matches **the builder** (including **`EXTERNAL_BUILDS_ROOT`**).
- **2026-05-06 — `resolveBuildsRootFromRepoRoot` (`src/builder/builds-root.sh`)**
  - **`./wsl-builder.sh`** and **`./review/component-review.sh`** both source **`src/builder/builds-root.sh`** after **`src/common/print.sh`** and user **`wsl-builds.conf`**.
  - Delivery phase 7 **`./review/build-review.sh`** should call **`resolveBuildsRootFromRepoRoot "${REPO_ROOT}"`** (same ordering), not reimplement **`EXTERNAL_BUILDS_ROOT`** trimming/`~` expansion.
- **2026-05-06 — Shared primitives** (historical name **`review-common.sh`**; file is now **`src/review/runner-common.sh`**)
  - **File:** `src/review/runner-common.sh` — sourced from **`src/review/component-review-main.sh`** (loaded by **`./review/component-review.sh`**); **not** referenced by the builder yet.
  - **Paths:** `pathForAuditScript "$BUILD_DIR" "$token"` etc. **BUILD_DIR** matches **the builder**: **`${BUILDS_ROOT}/`** plus the build directory name (first CLI argument). **BUILDS_ROOT** from **resolveBuildsRootFromRepoRoot**.

### Outstanding for this phase

*(None — phase complete. Optional Docker Bats for real **`dev-bash`/`shellcheck`** is tracked under **Global outstanding**.)*

---

## Delivery phase 3 — Shared aggregation helper

### Reference

**Goal (historical transition):** Replace ad hoc per-audit rollup with shared concern derivation owned by the runner. This phase is complete and preserved for traceability.

**Reviewable chunks:**

1. Implement helper path that consumes `checks`, `required_check_ids`, optional `custom_issue_policy` → runner-owned `concerns`.
2. Ensure pilot stdout remains measurement-only; runner derives and persists `concerns`.

**Spec refs:** [Measurement → concerns interface (runner, v1)](automated-builds-review-v1-spec.md#measurement-concerns-interface-runner-v1), [Concern derivation (`emitConcernsFromChecks`)](automated-builds-review-v1-spec.md#aggregation-concerns-runner-v1).

### Chunk checklist

- [x] 1 — Historical transition row (pre-2026-05-08 helper path; see phase 3 Handoff notes)
- [x] 2 — Pilot migration completed; final contract is measurement-only audit stdout + runner-owned `concerns`

### Handoff notes for later phases

- **2026-05-06 — Phase 3 complete (chunks 1–2 committed): pilot `shellcheck_audit.sh` uses aggregation helper**
  - **`builds/dev-bash/shellcheck_audit.sh`:** sources **`review-aggregation.sh`** from repo root; **`emitFinalJson`** builds final one-line JSON (**`component_reviewer_version`**, **`checks`**, **`evidence`**, plus **`review_result` / `review_result_label` / `review_concerns` / `reasons` / `summary`** from **`reviewAggregateFromChecks`**). **`requiredCheckIdsJson`** was **`["shellcheck_cli"]`** at commit (pilot single check); **2026-05-07** Decisions log: required ids use **audit-check catalogue stems** (e.g. **`cli-reported-version`**). Third aggregation argument **`''`** for default **`{}`** policy.
  - **Verify:** **`bash builds/dev-bash/shellcheck_audit.sh | jq .`**; **`./review/component-review.sh dev-bash shellcheck`**. **`./test/run-tests.sh`** passed after chunk **2** (lint + Docker Bats).
  - **Human-readable rollup strings** now match **`review-aggregation.jq`** (not phase **2** hand-tuned **`summary`** / **`reasons`** copy); machine **`review_result`** and **`checks`** payloads unchanged for the two pilot scenarios.
  - Spec / plan: [Measurement → concerns interface (runner, v1)](automated-builds-review-v1-spec.md#measurement-concerns-interface-runner-v1); phase **3** Reference above.
- **2026-05-06 — Phase 3 chunk 1: shared aggregation helper committed**
  - **Files:** historical row references previous aggregation helper files (`src/review/review-aggregation.sh`, `src/review/review-aggregation.jq`) from pre-restructure implementation.
  - **Policy:** **`required_check_ids`** drives **`review_result` 2** when a required row is missing or **`outcome` `inconclusive`**; unrouted **`issue`** rows (**`finding_kind`** not security/staleness/upstream_drift and no **`routes_by_audit_check_id`** route) force **2**. Optional **`routes_by_audit_check_id`** values **`"security"`** / **`"freshness"`** / **`"none"`**.
  - **Sourcing:** consumers **`source`** **`review-aggregation.sh`** from a resolved path (audit scripts live under **`builds/`**; compute repo root or **`src/review/`** relative path accordingly). **`_reviewAggJqPath`** is assigned when **`review-aggregation.sh`** is sourced.
  - **Verify helper:** after **`source src/review/review-aggregation.sh`**, call **`reviewAggregateFromChecks`** with **`jq`** `-cn` payloads for **`checks`** and **`requiredIds`** (omit third arg or use empty string for `{}`).

### Outstanding for this phase

*(None — phase complete.)*

---

## Delivery phase 4 — First `audit-check` module + helpers

### Reference

**Goal:** First reusable module under `audit-checks/` with the one-line stdout check object contract; thin helpers under `audit-check-helpers/` as needed.

**Reviewable chunks:**

1. One module from the [initial `audit-checks/` catalogue](automated-builds-review-v1-spec.md#audit-check-filenames-v1-signal-first) (pick the most informative for the pilot component).
2. Any small helpers required (no mandated stdout contract; must not set `review_result`).
3. Pilot audit composes the module(s), appends check rows, then calls aggregation helper.

**Definition of done:**

- Pilot component review is **meaningfully** signal-bearing (not only a stub), still advisory-only.

**Spec refs:** [Audit-check module output (v1)](automated-builds-review-v1-spec.md#audit-check-module-output-v1), audit helper library boundaries.

### Chunk checklist

- [x] 1 — First `audit-checks/*.sh` module (name: **`cli-reported-version.sh`**) with one-line check-object contract
- [x] 2 — Supporting `audit-check-helpers/` as needed (**historical note:** earlier helper API names in this phase used pre-2026-05-08 envelope/merge terminology)
- [x] 3 — Pilot audit composes checks + aggregation

### Handoff notes for later phases

- **2026-05-06 — Phase 4 complete (chunk 3 accepted + committed: pilot audit composed)**
  - **Historical (superseded by 2026-05-08 evidence relocation):** this chunk originally described a bundle-merge flow. Current contract is direct check-object emission with optional nested per-check `evidence`, and append-only check composition.
  - **Extend coverage** in phase **5** by adding more **`bash …/audit-checks/…`** invocations, appending each emitted check row into the running `checks` array, then expanding **`requiredCheckIdsJson`** (and optional **`custom_issue_policy`**) together—keep **judgment** in **`reviewAggregateFromChecks`** only.
  - **Inconclusive copy** for missing CLI now comes from the module (differs slightly from pre-chunk-3 pilot wording); machine **`review_result`** semantics unchanged.
  - **Verify:** **`bash builds/dev-bash/shellcheck_audit.sh | jq .`**; **`./review/component-review.sh dev-bash shellcheck`** (persists **`shellcheck_review.result.json`**). **`./test/run-tests.sh`** passed at chunk **3** acceptance (host with Docker).
- **2026-05-06 — Phase 4 chunk 2 accepted and committed (`review-measurement-bundle.sh`)**
  - **Historical (superseded by 2026-05-08 evidence relocation):** old helper file/API names in this row used pre-relocation bundle merges. Keep this row only as migration context.
  - **Current shape:** `measurement-bundle.sh` provides append-only check composition and no top-level evidence merge.
- **2026-05-06 — Phase 4 chunk 1 accepted and committed (`cli-reported-version.sh`)**
  - **File:** **`src/review/audit-checks/cli-reported-version.sh`** — signal-first catalogue name **`cli-reported-version`**; one-line check-object contract per spec [Audit-check module output (v1)](automated-builds-review-v1-spec.md#audit-check-module-output-v1).
  - **Composed into pilot in chunk 3** — **`shellcheck_audit.sh`** (**see newest Phase 4 handoff**).

### Outstanding for this phase

*(None — phase complete.)*

---

## Delivery phase 5 — Complete pilot component end-to-end

### Reference

**Goal:** For the **pilot component**, cover the **minimal viable checks** planned for v1 (up to the six initial modules in [Audit-check filenames (v1, signal-first)](automated-builds-review-v1-spec.md#audit-check-filenames-v1-signal-first) or a justified subset), with retries/timeouts behaviour per [Network and flake policy (v1)](automated-builds-review-v1-spec.md#network-and-flake-policy-v1).

**Reviewable chunks:**

- Add checks one or two at a time; adjust manifest and aggregation policy explicitly.
- Document concise manifest scalars in `audit.manifest.yaml` and rationale in `<slug>/audit.sh` comments as maintainers will rely on them.

**Definition of done:**

- One component is a **reference** implementation other audits can copy.

### Chunk checklist

- [x] All planned v1 checks for pilot present (list modules used: **`cli-reported-version`**, **`deb-installed-version`**, **`installer-validated-staleness`**, **`http-json-upstream-version`**, **`upstream-exact-match`**, **`upstream-semver-drift`** — last invoked only when **`compare_cli_to_github_semver`** is **`true`**; otherwise **`upstream-semver-drift`** is a **`skipped`** row without running the script)
- [x] Manifest + `audit.sh` reflect real policy
- [x] Retries/timeouts align with spec

### Handoff notes for later phases

- **2026-05-06 — Phase 5 complete (chunk 3 accepted + committed): retries/timeouts vs [Network and flake policy (v1)](automated-builds-review-v1-spec.md#network-and-flake-policy-v1)**
  - **Scope:** Confirm **`reviewHttpGetWithRetry`** matches policy; **no behavioural change** required beyond documentation—**chunk 3** reinforced **spec** paragraph **Shared helper behaviour (v1, `reviewHttpGetWithRetry`)** and **header comments** in **`src/review/audit-check-helpers/review-http-fetch.sh`** (cross-ref + concrete numbers: **3** attempts, **5xx** / **`000`** only, default **30s** **`--max-time`**).
  - **Verify:** read spec **Network and flake policy**; **`./review/component-review.sh dev-bash shellcheck`** (HTTP path via **`http-json-upstream-version.sh`** unchanged).
  - **Next:** **delivery phase 6** — incremental rollout of **`<slug>_audit.sh`** + **`<slug>_review.yaml`** (soft skip for missing audits remains **build-review.sh** / phase **7** concern; phase **6** Reference has batching rules).
- **2026-05-06 — Phase 5 chunk 2 committed: manifest `aggregation_notes` / `upstream_tracking` aligned with shipped audit**
  - **File:** **`builds/dev-bash/shellcheck_review.yaml`** — prose only; documents **`requiredCheckIdsJson`**, non-required **`http-json-upstream-version`**, gated **`upstream-semver-drift`**, required **`skipped`** vs **`inconclusive`** (per **`review-aggregation.jq`**), empty **`last_known_upstream`**, **`installer-validated-staleness`** semantics, apt vs GitHub API **measurement**.
  - **Verify:** read YAML; **`./review/component-review.sh dev-bash shellcheck`** unchanged. Spec: [Maintainer manifest (v1 minimal shape)](automated-builds-review-v1-spec.md#maintainer-manifest-v1-minimal-shape), [Measurement → concerns interface (runner, v1)](automated-builds-review-v1-spec.md#measurement-concerns-interface-runner-v1).
  - **Superseded:** phase **5** closed with chunk **3** (see newest phase **5** handoff).
- **2026-05-06 — Phase 5 chunk 1 committed: pilot composes full v1 `audit-checks/` catalogue**
  - **Reference audit:** **`builds/dev-bash/shellcheck_audit.sh`** — **`requiredCheckIdsJson`** catalogue stems **`["cli-reported-version","deb-installed-version","installer-validated-staleness","upstream-exact-match"]`** (via **`reviewAuditCheckIdFromModulePath`**); **`mergeEnvelopeLine`** / **`reviewMergeMeasurementBundles`** fold; **`emitFinalJson`** unchanged pattern from phase **4**.
  - **New modules:** **`deb-installed-version.sh`**, **`installer-validated-staleness.sh`**, **`upstream-exact-match.sh`**, **`upstream-semver-drift.sh`**, **`http-json-upstream-version.sh`** (+ existing **`cli-reported-version.sh`**).
  - **Helpers:** **`review-manifest-scalar.sh`** ( **`reviewManifestScalar`** — single-line YAML scalars only), **`review-http-fetch.sh`** ( **`reviewHttpGetWithRetry`**, 3 attempts, backoff on **5xx** / transport **`000`**); **`http-json-upstream-version.sh`** sources fetch helper via path under **`audit-check-helpers/`**.
  - **Manifest keys (pilot):** **`compare_cli_to_github_semver`**, **`installer_validated`**, **`installer_staleness_max_days`**, **`last_known_upstream`** (empty ⇒ **`upstream-exact-match`** **`skipped`**). **`component-review.sh`** still does **not** parse YAML.
  - **Verify:** **`bash builds/dev-bash/shellcheck_audit.sh | jq .`**; **`./review/component-review.sh dev-bash shellcheck`**. Needs **`jq`**, **`curl`**, **`dpkg-query`** + installed **`shellcheck`** for a full green local story; GitHub GET uses **`https://api.github.com/repos/koalaman/shellcheck/releases/latest`** and **`.tag_name`**.
  - **Superseded:** chunks **2–3** completed (manifest prose + retries/timeouts); see newer phase **5** handoffs.
- **2026-05-06 — Phase 5 not started; phase 4 left a composed pilot**
  - **`shellcheck`** audit already uses **one** catalogue module (**`cli-reported-version`**); phase **5** adds more checks and manifest/policy alignment—see phase **4** handoff **2026-05-06 — Phase 4 complete** for the merge pattern.

### Outstanding for this phase

*(None — phase complete.)*

---

## Delivery phase 6 — Roll out to more components and builds

### Reference

**Goal:** Add `<slug>/audit.sh` + `<slug>/audit.manifest.yaml` (and tracked `<slug>/review.result.json` when present per spec) across the tree, staying within **v1** scope.

**Important:** Do **not** attempt “every component in every build” in a single change set before human commit. Use **increments**:

- Prefer **one build directory** or a **small batch of components** per reviewable chunk.
- Missing `<slug>/audit.sh` remains a **soft skip** for future `build-review.sh`; partial coverage is acceptable while incremental.

**Spec refs:** [v1 skip policy](automated-builds-review-v1-spec.md#v1-skip-policy-soft-build-review), [Audit-check filenames (v1, signal-first)](automated-builds-review-v1-spec.md#audit-check-filenames-v1-signal-first) (initial module set), [Audit helper library](automated-builds-review-v1-spec.md#audit-helper-library-shared-measurement).

### Chunk checklist

*Add one bullet per scoped batch (copy template row as needed).*

- [ ] Increment: *(build)* — *(tokens/components)* —
- [ ] Increment: —
- [ ] Increment: —

### Handoff notes for later phases

- **2026-05-06 — Phase 6 next (phase 5 complete on reviewer branch)**
  - **Reference implementation:** `builds/dev-bash/shellcheck/audit.sh`, `builds/dev-bash/shellcheck/audit.manifest.yaml`, **`./review/component-review.sh dev-bash shellcheck`** (paths updated 2026-05-09 — see decision row).
  - **Scope discipline:** one build directory or a **small batch** of components per human-accepted chunk; do not attempt full-tree coverage in one change set (see phase **6** Reference).
  - **`build-review.sh`** is **delivery phase 7** only—missing `<slug>/audit.sh` is not yet a build-level soft skip in tooling.

### Outstanding for this phase

*(None.)*

---

## Delivery phase 7 — Build review orchestrator (`build-review.sh`)

### Reference

**Goal:** Implement **spec Phase 2**: `./review/build-review.sh` walks `VALID_INSTALL_COMPONENTS` in CSV order, enforces presence of `builds/<build>/<slug>/install.sh`, soft-skips missing audits with **human-visible** listing of skipped tokens, delegates to `./review/component-review.sh`, and follows build-level exit semantics.

**Shared helpers (same pattern as `./review/component-review.sh`):** After **`src/common/print.sh`** and user **`wsl-builds.conf`**, source **`src/builder/builds-root.sh`** and call **`resolveBuildsRootFromRepoRoot "${REPO_ROOT}"`** so **`BUILDS_ROOT`** matches **the builder**. Prefer **`src/`** helpers over parallel implementations.

**Reviewable chunks:**

1. Load build metadata / CSV the same way as dispatch (see spec + `conf.sh`; **no** whitespace trimming on tokens—match [`src/builder/install-dispatch.sh`](../src/builder/install-dispatch.sh) exactly).
2. Per-entry orchestration rules (failure vs skip vs run).
3. Delegation to `./review/component-review.sh` with **stable CLI** preserved.
4. Human output for skips and final status.

**Definition of done:**

- A maintainer can run one command for a full build advisory review path; skips are obvious in output.

**Spec refs:** [Component enumeration](automated-builds-review-v1-spec.md#component-enumeration-v1-dispatch-aligned), build review exit codes, skip policy.

### Chunk checklist

- [ ] 1 — Load metadata / CSV aligned with dispatch (no token trimming)
- [ ] 2 — Orchestration (install missing ⇒ fail; audit missing ⇒ skip + report)
- [ ] 3 — Delegate to `component-review.sh` (stable CLI documented in Handoff if needed)
- [ ] 4 — Human-visible skip listing and final status

### Handoff notes for later phases

*(Usually empty once v1 rollout is finished; keep for post-v1 follow-ups.)*

*(No entries yet.)*

### Outstanding for this phase

*(None.)*

---

**Canonical behaviour:** [automated-builds-review-v1-spec.md](automated-builds-review-v1-spec.md).
