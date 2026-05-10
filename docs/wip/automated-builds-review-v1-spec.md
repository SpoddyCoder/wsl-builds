# Automated builds review — v1 specification

This document specifies **v1** of an **advisory-only** way for maintainers to see which install components may need attention (security, drift, or stale validation). It is **not** a gate for installs or CI unless the project chooses that later.

## Goal (v1)

Run a **build review** over a **build directory**: walk the build’s **registered** component list in **CSV order** (same source as install dispatch—see [Component enumeration (v1): dispatch-aligned](#component-enumeration-v1-dispatch-aligned)). For each entry, **run a component review** only when **`<slug>/audit.sh`** exists; otherwise apply the **v1 soft skip** ([Skip policy](#v1-skip-policy-soft-build-review))—no error, no result JSON for that token. Each invoked audit script emits **audit items** (measurement) only **on stdout**; **`review/component-review.sh`** merges runner metadata, derives factual **`concerns`** from **`checks`** and policy inputs, validates, and persists **`review_result`**-free component JSON ([Review result JSON (component artefact, v1)](#review-result-json-component-artifact-v1)). Future **build review** tooling may apply higher-layer **policy views** (**`review_result`**, **`summary`**, **`reasons`**). **v1** uses **JSON** for structured measurements and factual roll-up dimensions.

Conceptually: **facts** (**`checks`** with per-check **`evidence`**, plus **`concerns`**) persist on **`<slug>/review.result.json`**. Headline verdicts and narratives stay **above** that file ([Facts vs policy views](#facts-vs-policy-views)).

### Facts vs policy views

| Artefact layer | Holds |
| -------------- | ----- |
| **Component persisted JSON** (**`<slug>/review.result.json`)** | **Measurement report:** **`checks`** (each row may include **`evidence`**), runner-owned **`concerns`** (four booleans), plus runner merge fields (**`component_reviewer_version`**, **`build`**, **`component`**, **`review_completed`**). Audits emit **`checks`**, **`required_check_ids`**, optional **`custom_issue_policy`** on stdout—the runner derives **`concerns`** and strips policy inputs before persist ([Audit measurement stdout (Phase 1)](#audit-measurement-stdout-phase-1)). |
| **Future build-layer review** (**`build-review.sh`**, aggregates) | **Policy views:** e.g. **`review_result`** **0–2**, paired **`review_result_label`**, **`summary`**, **`reasons`**—out of scope for the component artefact contract in this iteration (see [`policy-views-resturcture.md`](policy-views-resturcture.md)). |

### Implementation rollout

The **build review** loop below is fully specified so a **Phase 2** **`review/build-review.sh`** CLI (sourced implementation under **`src/review/`**, same pattern as **`review/component-review.sh`**) can implement it without rediscovering rules. **Phase 1** ships **`review/component-review.sh`** only—one component at a time, with a **stable CLI** that **build-review** will call later. Until Phase 2 exists, run component reviews **per token** manually or from ad-hoc automation. **`<slug>/audit.sh`** must emit only the measurement envelope (**[Audit measurement stdout (Phase 1)](#audit-measurement-stdout-phase-1)**); **`concerns`** are **never** authored by audits.

Numbered **delivery** phases in the repo—and how they map to **Phase 1** / **Phase 2** above—are in [automated-builds-review-v1-delivery-plan.md](automated-builds-review-v1-delivery-plan.md).

### Review tooling dependencies (v1)

Shippable review runners and shared `src/review/` code may rely on **host** tools (for example `jq`, a YAML parser, `curl`). **v1 policy:**

- **Document** every such dependency in `CONTRIBUTING.md` (what to install, and where it is used)—that file is the **canonical maintainer-facing list**, not an auto-install step inside the review scripts.
- **Do not install** dependencies from `src/review/*.sh`, `audit-checks/`, or `audit-check-helpers/` (no `apt`, `brew`, silent download-to-path bootstrap, etc.). If a required tool is missing, **exit non-zero** with a message that points maintainers at `CONTRIBUTING.md`.

### Maintainer documentation (v1)

Maintainer-facing **prose** for the automated review (what it does, layout, manifests, how to run Phase 1) lives in [`review/README.md`](../review/README.md). This spec remains the **canonical** contract for behaviour; new maintainer docs for this system should go there rather than duplicating normative detail in another long form.

A non-normative maintainer **debug harness** (`review/review-debug.sh`) exposes `run-check` / `run-audit` / `run-review` / `run-e2e` modes (legacy: `check` / `audit` / `component` / `scenario`) for developing audits and audit-check modules in isolation; deterministic offline scenarios live under `builds/fixture-review/` and are consumed by both that harness and `test/docker/review-fixture-tests.bats`. Neither changes the contracts in this spec — see [`review/README.md`](../review/README.md) for usage.

## Terminology (layers)

| Layer | Meaning |
| ----- | ------- |
| **Build review** | Walks **`VALID_INSTALL_COMPONENTS`** in CSV order ([enumeration](#component-enumeration-v1-dispatch-aligned)); **soft skip** when **`<slug>/audit.sh`** is missing ([policy](#v1-skip-policy-soft-build-review)). |
| **Component review** | For **one** CSV token: invoke **`<slug>/audit.sh`**, validate **measurement stdout** and **persisted artefact**, write **`<slug>/review.result.json`**, optional short acknowledgement. Does **not** install or mutate the target system — only **the builder** (`./wsl-builder.sh`) does that. |
| **Audit** | Measurement inside `<slug>/audit.sh`: populate `checks` (including per-check `evidence` when useful), emit `required_check_ids` and optional **`custom_issue_policy`** on stdout. **Must not** set verdict fields or **`concerns`**. Judgment-heavy fields move to **[Future build-layer policy](#facts-vs-policy-views)** when implemented. Concern derivation is **[runner-owned](#aggregation-concerns-runner-v1)**. |

### Language contract (normative)

This spec is the source of truth for wording in the automated builds review domain. Use these canonical terms in docs, comments, and user-facing review text:

| Canonical term | Definition |
| -------------- | ---------- |
| `audit catalogue` | Reusable check scripts under `src/review/audit-checks/`. |
| `check module` | One executable script in the audit catalogue. |
| `check module name` | Module filename without `.sh` (for example `upstream-semver-drift`). |
| `check_id` | Stable per-check identifier on emitted check rows (`audit_check_id` field). |
| `check module args` | Positional arguments passed to a check module after `<check_id>`. |

Deprecated term: `stem`. Keep it only in historical notes; do not use it in current prose or symbol naming.

Shared review **libraries** (sourced by **`review/*.sh`** and by **`builds/**/audit.sh`**), **audit-check-helpers**, **checks-rollup**, validation, and (for Phase 2) the **build-review** orchestrator body live under **`src/review/`**. Files under **`src/review/audit-checks/`** are the intentional exception to “everything under `src/` is sourced”: **`audit-flow.sh`** runs them as **`bash`** subprocesses with a one-line JSON contract—they are **not** maintainer CLIs. Per-component install and review files live together under **`builds/<build>/<slug>/`**: `install.sh` (sourced by **the builder** dispatch), `audit.sh`, `audit.manifest.yaml`, `review.result.json`.

**Review CLIs** (maintainer **invocation** under **`review/`**; paths: [Paths and filenames (v1)](#paths-and-filenames-v1)):

- **`review/component-review.sh` (Phase 1):** **Component review** for one build + one CSV token—invoke **`<slug>/audit.sh`**, validate envelopes, derive **`concerns`**, persist **`<slug>/review.result.json`**. **Ship first**; treat the invocation contract as **stable** for Phase 2.
- **`review/build-review.sh` (Phase 2, planned):** **Build review** as specified in this document—walk **`VALID_INSTALL_COMPONENTS`**, **soft skip**, invoke **`review/component-review.sh`** once per non-skipped entry, human reporting for skips, **build review** exit semantics ([Process exit codes vs structured state](#process-exit-codes-vs-structured-state)). **Build-level** roll-up semantics remain [as scoped](#shared-abstraction-v1-scope). **Implementation** is under **`src/review/`**; maintainers run the repo **`review/`** script only.

## Component enumeration (v1): dispatch-aligned

v1 **build review** discovers which components to consider from the **same place install dispatch does**: the **`VALID_INSTALL_COMPONENTS`** value set in **`builds/<build>/conf.sh`** via **`registerBuildMetadata`** (see [`src/builder/build-metadata.sh`](../src/builder/build-metadata.sh) and the loop in [`src/builder/install-dispatch.sh`](../src/builder/install-dispatch.sh)). **Order** is the **CSV order** for that string, with **comma-splitting and token strings identical to dispatch** (same `IFS=',' read -r -a` behaviour—**do not** trim whitespace; optional spaces inside `conf.sh` would produce different tokens and **must** not be normalized only in review).

**Tokens and filenames**

> **`<slug>`** is the **on-disk fragment** with hyphens from the CSV token mapped to underscores (**same rule as install dispatch**). It is **not** necessarily identical to the canonical token string.

- **Canonical component token** (builder argument, `component` field in review JSON): the CSV string with **hyphens preserved** (e.g. `mysql-client`, `cuda132`).
- **Install script:** `builds/<build>/<slug>/install.sh` — same path **the builder** sources via `src/builder/install-dispatch.sh`.
- **Audit script:** `builds/<build>/<slug>/audit.sh` (review-only subdirectory named after the slug).
- **Maintainer manifest and persisted review result:** `builds/<build>/<slug>/audit.manifest.yaml` (maintainer-edited, machine-readable; read by **`<slug>/audit.sh`** and helpers—not parsed or rewritten by **`component-review.sh`**), `builds/<build>/<slug>/review.result.json` (runner-written). The `<slug>/` directory groups all review-only files for one component together.

Example for CSV token `mysql-client` (`<slug>` = `mysql_client`): install and review files live under `builds/<build>/mysql_client/` — `install.sh`, `audit.sh`, `audit.manifest.yaml`, `review.result.json`.

**Per CSV entry (in order)**

1. **`builds/<build>/<slug>/install.sh` missing** — Metadata is inconsistent with the tree (that install could not be sourced by dispatch). **Build review** treats this as **orchestration failure** (**exit non-zero**).
2. **`<slug>/audit.sh` missing** — Apply **v1 soft skip** ([below](#v1-skip-policy-soft-build-review)); do **not** run a component review and do **not** require **`<slug>/review.result.json`**.
3. **`<slug>/audit.sh` present** — Run a **component review** as defined elsewhere in this spec.

**Not enumerated:** A per-component `install.sh` under some `builds/<build>/<slug>/` that is **not** in **`VALID_INSTALL_COMPONENTS`** is **out of scope** for the v1 build-review loop (adding it to the CSV is how it becomes part of the official set).

### v1 skip policy (soft, build review)

v1 uses a **soft skip** for missing audit scripts so maintainers can grow **`<slug>/audit.sh`** coverage without breaking **`review/build-review.sh`** once that orchestrator exists.

- **Not a failure:** A skip is **not** an install problem and **never** by itself forces **build review** **exit non-zero**.
- **Exit 0 with skips is valid:** **Build review** exits **0** when the orchestrator finishes the **controlled** path: metadata and CSV load succeeded, every listed **`builds/<build>/<slug>/install.sh`** exists, every **run** component review emitted **valid** JSON, and nothing **uncontrolled** broke. Skips do not need JSON.
- **Human output (required):** The **build review** orchestrator **must** report **every** skipped canonical token (CSV form), for example one line per skip or a closing summary line, so a successful exit does not read as “everything was audited” when it was not. Implementation: **`review/build-review.sh`** (Phase 2; body under **`src/review/`**).
- **Strict coverage (fail if any skip)** is **out of scope for v1**; a later optional flag or revision of this spec can add it.

## Component **`concerns`** (four factual dimensions)

The **persisted** component JSON includes **`concerns`**, always exactly these keys (all booleans, always present—included even when **false**):

```json
"concerns": { "security": false, "freshness": false, "skipped": false, "incomplete": false }
```

- **`security`:** **true** iff at least one **`issue`** row routes into the security class (typically `finding_kind` **`security`**, or **`custom_issue_policy.routes_by_audit_check_id`** **`"security"`**).
- **`freshness`:** **true** iff at least one **`issue`** row routes into the freshness/staleness class (`finding_kind` **`staleness`** or **`upstream_drift`**, or policy **`"freshness"`**).
- **`skipped`:** **true** iff **any** **`checks`** row has **`outcome` `skipped`**.
- **`incomplete`:** **true** iff the story is incomplete for rollup: **any** **`required_check_ids`** row is **missing**, **any required** row has **`outcome` `inconclusive`**, **or** any **`issue`** row is **unrouted** for top-level classification (cannot map to security, freshness, or explicit **`"none"`** exclusion via **`routes_by_audit_check_id`** per [Concern derivation rules](#aggregation-concerns-runner-v1)).

Unlike the earlier **`review_result` 2 / concern-zeroing coupling**, **`security`**/**`freshness`** remain **orthogonal** from **`incomplete`**: factual signals can all be surfaced independently ([`policy-views-resturcture.md`](policy-views-resturcture.md)).

**Future build-review policy:** integer **`review_result`** **0–2**, **`review_result_label`**, **`summary`**, **`reasons`** interpret these facts—not stored on **`<slug>/review.result.json`** in v1 of this split.

## Process exit codes vs structured state

**Component review (Phase 1):** **`review_result`** is **not** a process exit discriminator. Prefer:

- **Exit 0:** **component-review** merged, validated **[Review result JSON (component artefact, v1)](#review-result-json-component-artifact-v1)**, and persisted (**`<slug>/review.result.json`**).
- **Exit non-zero:** audit non-zero stdout parse failure; measurement validation failure; concern merge failure; write failure—or other **uncontrolled** errors.

Audits (**`<slug>/audit.sh`**) also finish **exit 0** after printing **valid measurement JSON** (**[Audit measurement stdout (Phase 1)](#audit-measurement-stdout-phase-1)**). Do not infer concern severity from audit **`$?`**.

For **build review** (Phase 2, future): the orchestrator exits **non-zero** on metadata/orchestration failure and **0** on the controlled loop; **policy views** (**`review_result`**, summaries) belong in that layer's output model when specified. **Soft skip** when **`<slug>/audit.sh`** is missing for an entry (**[v1 skip policy](#v1-skip-policy-soft-build-review)**) yields **no** component JSON for that token.

### Runner validation (Phase 1)

**Structured output channel (audit stdout):** On a controlled path, **`<slug>/audit.sh`** prints **exactly one JSON object** on **stdout**, as **one logical line** with no embedded newlines—same mechanics as capture for [Audit-check module output (v1)](#audit-check-module-output-v1). **Stderr** is diagnostics only.

#### Audit measurement stdout (Phase 1)

The audit object **must** satisfy **measurement envelope** validation before merge:

**Required**

| Field | Type | Purpose |
| ----- | ---- | ------- |
| `component_reviewer_version` | number | Exactly **1**. |
| `checks` | array | Per-run rows ([Audit item outcomes (normalized)](#audit-item-outcomes-normalized)). |
| `required_check_ids` | array of strings | Which **`audit_check_id`** values **must** have a row for a **complete** story (ordering not significant). Runner uses this for **`concerns.incomplete`**. Empty array allowed. |

**Optional**

| Field | Type | Purpose |
| ----- | ---- | ------- |
| `custom_issue_policy` | object | **Fringe:** **`routes_by_audit_check_id`** maps **`audit_check_id`** → **`"security"`**, **`"freshness"`**, or **`"none"`** for **`issue`** rows not classified solely by **`finding_kind`**. Omit or **`{}`** when unused. |

**Forbidden on audit stdout (runner rejects):**

`review_result`, `review_result_label`, `review_concerns`, **`concerns`**, `reasons`, `summary`, top-level `evidence`, and runner merge-only fields (**`build`**, **`component`**, **`review_completed`**) until a later revision folds them differently.

Implementation: **`validateAuditMeasurementJson`** in **`merged-result-validation.sh`**.

When **`component-review`** rejects the audit envelope (**exit non-zero**, diagnostic), **`<slug>/review.result.json`** is **not** created nor overwritten.

#### Persisted artefact validation (merged JSON) {#persisted-artefact-validation-merged-json}

After the runner merges **`build`**, **`component`**, **`review_completed`** and attaches runner-derived **`concerns`**, the **persisted document** ([Review result JSON (component artefact, v1)](#review-result-json-component-artifact-v1)) **must**:

- include **`concerns`** with **exactly** **`security`**, **`freshness`**, **`skipped`**, **`incomplete`** (all booleans);
- omit **`required_check_ids`**, **`custom_issue_policy`**, top-level **`evidence`**, verdict fields (**`review_result`**, **`review_result_label`**), **`review_concerns`**, **`reasons`**, **`summary`**.

**Persisted file:** On any validation failure, the runner **must not** overwrite **`<slug>/review.result.json`**.

Audits (**`<slug>/audit.sh`**) that **exit non-zero** — **no** write; same as measurement validation failure.

Optional later: a narrow **`$?` ↔ policy** mapping for consumers that insist on shell exit semantics only.

## Audit model (measurement only)

**`<slug>/audit.sh`** is **measurement only** for **[Audit measurement stdout (Phase 1)](#audit-measurement-stdout-phase-1)**:

1. **Compose** checks using **audit check modules and helpers** ([Audit helper library (shared measurement)](#audit-helper-library-shared-measurement)) and **`custom`** measurement where appropriate.
2. **Emit stdout JSON** including **`checks`**, **`required_check_ids`**, optional **`custom_issue_policy`**.

**Forbidden** on stdout: **`concerns`** and all **policy-view** verdict fields (**`review_result`**, **`review_result_label`**, **`reasons`**, **`summary`**, legacy **`review_concerns`**). **`audit-checks/`**, **`audit-check-helpers/`**, and inline **`custom`** code **must not** set verdict fields—they **never** authored **`concerns`** in this model.

Concise maintainer context belongs in **`audit.manifest.yaml`** (for example **`upstream_tracking`**, optional **`notes`**) and in **`<slug>/audit.sh`** comments; **`required_check_ids`** and **`custom_issue_policy`** are **explicit on audit stdout** so **`component-review.sh`** derives **`concerns`** deterministically (**[Concern derivation (`emitConcernsFromChecks`)](#aggregation-concerns-runner-v1)**).

**Process contract:** **`exit 0`** after emitting **well-formed measurement JSON** on **stdout**. **`exit non-zero`** — **uncontrolled** failure; no trustworthy structured output (**[Process exit codes vs structured state](#process-exit-codes-vs-structured-state)**).

## Audit helper library (shared measurement)

Growing a **consistent library of reusable audit checks** (and shared **measurement** helpers) under **`src/review/`** is the **main scaling lever**: new components mostly **compose** existing checks instead of reimplementing HTTP, retries, version compares, and manifest patterns. **Concern derivation** (**`emitConcernsFromChecks`** from **`checks-rollup.*`**) is **runner-owned** after audit stdout—**judgment-heavy prose** awaits **build-review** tooling.

**Layout (v1 target)**
- **`src/review/audit-checks/`** — one file (or small unit) per **reusable measurement entry point** that `<slug>/audit.sh` **source**s or **invoke**s; typically **one [check object](#audit-check-module-output-v1) line per invocation**. A module may be **thin** (compare facts the caller already obtained) or **compose `audit-check-helpers/`** for fetch+parse+compare when that end-to-end story is shared (see [Composition pattern (v1 recommendation)](#composition-pattern-v1-recommendation)).
- **`src/review/audit-check-helpers/`** — cross-cutting utilities (timeouts, retries, parsers). Do not emit **`concerns`** or verdict/policy-view fields.

### Composition pattern (v1 recommendation)

v1 does **not** require **`<slug>/audit.sh`** to fetch all facts before every **`audit-checks/`** call. **Default:** when the **same** fetch+normalize+compare story repeats across components, implement it as a **reusable `audit-checks/`** module that **uses helpers internally**, keeping **`<slug>/audit.sh`** focused on composing measurement and emitting **`required_check_ids`** (**[Audit measurement stdout (Phase 1)](#audit-measurement-stdout-phase-1)**).

**Escape hatch:** when wiring is **one-off**, unstable, or would **over-parameterize** a shared module, **orchestrate in `<slug>/audit.sh`** (call **`audit-check-helpers/`** or inline fetch), then run a **thin** **`audit-checks/`** compare—or append **custom** **[normalized](#audit-item-outcomes-normalized)** rows without the one-line check object contract.

**Boundaries:** anything that prints the **one-line stdout check object** is an **`audit-checks/`** module, not an **`audit-check-helpers/`** entry point. Helpers may expose **`source`d functions**; a **thin** `audit-checks/*.sh` wrapper (argv → call helper → print check object) is fine for DRY.

**Hybrid** is normal: shared **`audit-checks/`** for the repeated path and **custom** measurement in the same **`<slug>/audit.sh`** for edge cases.

### Audit-check filenames (v1, signal-first)

Files under **`src/review/audit-checks/`** use **Convention B**: **signal-first**, **kebab-case**, filenames shaped as `dimension-technique.sh` (for example `upstream-exact-match.sh`). Lead segment names the **dimension** (installer-validated date, upstream, deb package, CLI, HTTP JSON); trailing segment names the **technique**. This keeps filenames short and avoids overloaded terms (“opaque”) in filenames—use **exact match** when the measurement is identity/equality **without semver or distro ordering**.

**Phase 1** ships a **small initial set** below; add more modules as ecosystems need them. **Advisory/CVE** helpers are intentionally **not** pinned to a sixth filename here—they stay optional and often `custom` until coordinates repeat across components ([CVE and advisory policy (v1)](#cve-and-advisory-policy-v1)).

| Filename | Measurement (summary) |
| -------- | --------------------- |
| `installer-validated-staleness.sh` | `installer_validated` (`YYYY-MM-DD`) vs max age threshold. |
| `upstream-exact-match.sh` | `last_known_upstream` vs observed upstream string (**equality after script-defined normalization**; no semver or dpkg ordering). |
| `upstream-semver-drift.sh` | Semver-style compare vs manifest (+ optional fetched “latest,” per component policy). |
| `deb-installed-version.sh` | Installed `dpkg` / `apt`-visible version for one named package per invocation (`<slug>/audit.sh` calls again for additional packages). |
| `cli-reported-version.sh` | Parses version text from program `--version` output (caller supplies command and extract pattern). |
| `http-json-upstream-version.sh` | Timed HTTP GET plus JSON extraction → **observed** upstream **fact**, typically feeding `upstream-*` checks. |

**Terminology:** the top-level JSON key `checks` ([top-level `checks`](#top-level-fields-required)) holds per-run outcomes; the source tree directory `audit-checks/` houses **code** for reusable measurement—different concepts.

### Audit-check module output (v1)

v1 **locks** how a reusable file under **`audit-checks/`** hands measurement to **`<slug>/audit.sh`**. **Per-check inputs** (URLs, package names, thresholds, and so on) stay **call-specific**; only this **stdout check object** contract is shared.

- **Stdout (machine):** On **exit 0**, the module prints **exactly one line** whose entire content is a single JSON **object** (one logical line—no embedded newlines in the string so downstream `read`/append stays reliable). The object itself is one [normalized check object](#audit-item-outcomes-normalized): `audit_check_id`, `outcome`, `detail`, optional `finding_kind` / `severity`, and optional nested `evidence` object with factual keys for that check only (keys use **snake_case**).
- **Stderr:** Human-readable diagnostics only; **not** parsed for structured output.
- **Exit code:** **0** means a **controlled** result: stdout is the check object above. **Non-zero** means **uncontrolled** failure for that invocation; **`<slug>/audit.sh`** must not treat stdout as valid JSON (same spirit as [Process exit codes vs structured state](#process-exit-codes-vs-structured-state)).

Example stdout line (illustrative):

```json
{"audit_check_id":"upstream_version","outcome":"passed","detail":"Observed upstream matches last_known_upstream.","evidence":{"observed_upstream":"22.14.0"}}
```

**Several audit items in one component:** v1 **does not** put multiple checks in one module line. For multiple packages, URLs, or coordinates, **`<slug>/audit.sh`** invokes a check module **once per item**, passing different arguments each time. Prefer **distinct `audit_check_id` values** per item when that clarifies logs and **`required_check_ids`** ([`audit_check_id` vs `finding_kind`](#audit_check_id-vs-finding_kind)); duplicate `audit_check_id` strings are not forbidden by this spec if honest for the story.

**`audit-check-helpers/`:** Building blocks only—**no** required one-line envelope. They may be **sourced** by check modules or by **`<slug>/audit.sh`** directly; only files intended as “a complete audit item” under **`audit-checks/`** follow this contract.

### Conventions (`audit-checks/` and helpers)

- Helpers and check modules implement **audit item measurement only**. Reusable **`audit-checks/`** scripts follow [Audit-check module output (v1)](#audit-check-module-output-v1); **`<slug>/audit.sh`** parses each line and appends the check object into **`checks`**.
- They **must not** set **`review_result`**, **`review_result_label`**, **`review_concerns`**, **`concerns`**, **`reasons`**, or **`summary`**.
- **Per-component composition:** each script **chooses** which pieces apply (for example semver-style upstream compare for a Node component, distro-style version ordering for an `apt`-tracked package, HTTP+JSON for a release API). There is no requirement to use every module.
- **Custom paths:** when nothing fits (opaque tags, SHAs, vendor-specific pages), **`<slug>/audit.sh`** implements measurement inline or locally—same [normalized check object](#audit-item-outcomes-normalized) vocabulary and **`evidence`** keys as shared modules; no second on-disk JSON shape for the finished review JSON.
- **Guardrail:** avoid **one** monolithic abstraction that every ecosystem must fight; prefer **many small `audit-check-helpers/`** building blocks and **`audit-checks/`** modules **sized by reuse** (thin compare-only *or* fetch+compare composed from helpers), plus **explicit custom** where needed.

### Illustrative kinds

- **HTTP / fetch:** timed requests, size limits, simple JSON or header parsing used by several components.
- **Version compare (semver-oriented):** ordering or equality for `major.minor.patch`-style strings where that is honest for the upstream.
- **Version compare (distro-oriented):** ordering or equality for packaging conventions (for example Debian-style version strings) where a shared implementation is worthwhile.
- **Time / staleness:** parse manifest dates, compare against thresholds (often alongside manifest fields like `installer_validated`).
- **Advisory patterns:** shared query or filter steps only where coordinates and APIs repeat across components; ecosystem-specific advisory logic may stay `custom`.

### Version strings: manifest vs script (v1 decision)

The maintainer manifest stores **values only**—for example `last_known_upstream` as a **plain string** with **no encoded comparison kind** (“semver vs deb vs equality-only”). v1 **does not** add manifest fields that duplicate that—it would drift from `<slug>/audit.sh`.

**Interpretation is owned by** `<slug>/audit.sh`: which `audit-checks/` module applies ([Audit-check filenames](#audit-check-filenames-v1-signal-first)), whether ordering is meaningful, and when to mark an upstream check `inconclusive` instead of `passed`/`issue`. Equality-only comparisons use `upstream-exact-match.sh`; semver ordering uses `upstream-semver-drift.sh`; Debian-style ordering stays in `audit-check-helpers/` (distro-aware compare) or `custom`. Reviewers who need the story read the script (and any comments there). Per-check `evidence` should still carry the **observed** upstream value (and related facts) so audits and diffs stay grounded.

## Measurement → concerns interface (runner, v1) {#measurement-concerns-interface-runner-v1}

This subsection locks how **`checks`**, **`required_check_ids`**, and optional **`custom_issue_policy`** (**audit stdout**) become runner-owned **`concerns`**.

### Interface: **`checks`** is the structured input for concern derivation

- **Boundary:** **`emitConcernsFromChecks`** (jq **`checks-rollup.jq`**, shell **`checks-rollup.sh`**) consumes **`checks`**, **`requiredIds`**, and **`policy`**. Measurement helpers **must not** set **`concerns`** nor verdict/policy-view fields ([Facts vs policy views](#facts-vs-policy-views)).
- **Per-check `evidence`:** Humans/diffs/debug only. Concern derivation must not rely on `evidence` alone for dimensional facts—classification belongs in **`checks`** rows (**`detail`** and structured hints).
- **Maintainability:** **`<slug>/audit.sh`** emits **`required_check_ids`** on stdout (and **`custom_issue_policy`** when fringe routing needs it); longer human explanation belongs in **`<slug>/audit.sh`** comments or concise manifest scalars.

### `audit_check_id` vs `finding_kind`

- **`audit_check_id`:** Stable id per **`checks`** row; must align with **`required_check_ids`** for **`incomplete`** detection.
- **`finding_kind` (on `issue`):** Routes **`issue`** rows into **`concerns.security`** vs **`concerns.freshness`** (**`security`**, **`staleness`**, **`upstream_drift`**, **`custom`/blank** + policy).
- **Fringe cases:** **`custom_issue_policy.routes_by_audit_check_id`** (**`security`**|**`freshness`**|**`none`**) resolves **`finding_kind`** **`custom`/blank`; **`none`** excludes the row from security/freshness without forcing **`incomplete`**.

### Concern derivation (`emitConcernsFromChecks`) {#aggregation-concerns-runner-v1}

Concrete implementation **`emitConcernsFromChecks`** (**`checks-rollup.sh`**, **`checks-rollup.jq`**) emits four booleans per [Component **`concerns`**](#component-concerns-four-factual-dimensions):

1. **`incomplete`** if any **`requiredIds`** lacks a **`checks`** row, any required row is **`inconclusive`**, or any **`issue`** is **unrouted** (cannot map to **`security`** or **`freshness`**, and not **`routes_by_audit_check_id`** **`none`**).
2. **`security`** / **`freshness`** iff any routed **`issue`** hits those buckets (**orthogonal** to **`incomplete`**).
3. **`skipped`** iff any row has **`outcome` `skipped`**.

**Unrouted:** **`finding_kind`** **`custom`** or blank on an **`issue`**, without a usable **`routes_by_audit_check_id`** entry, does not map to **`security`**, **`freshness`**, or **`none`** ⇒ **`incomplete`**.

A future **`build-review.sh`** may map these facts plus **`checks`** onto **`review_result` 0–2**, **`reasons`**, **`summary`**—out of scope for the flattened component file ([Facts vs policy views](#facts-vs-policy-views)).

## Audit item outcomes (normalized)

Each `checks` array entry describes **one audit item**. Use this vocabulary for `outcome`:


| `outcome`      | Meaning                                                                                                                                                                                                     |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `passed`       | The item ran to a clear **passing** verdict.                                                                                                                                                                |
| `issue`        | The item ran to a clear **negative** verdict for that **dimension** (security, drift, staleness, etc.)—not an infrastructure fault. Prefer `issue` over `failed` so `failed` is not read as “script broke.” |
| `skipped`      | Not applicable for this component or intentionally not run; explain in `detail`.                                                                                                                            |
| `inconclusive` | **Controlled** but no reliable verdict—timeout, upstream error, ambiguous identity, missing identifiers. Maps the “timeout or other controlled error” case; it is **not** an uncontrolled run.              |


**Uncontrolled failure** (crash, bug, invalid JSON) is **not** an audit-item outcome: it is **non-zero exit** and no valid result document.

When `outcome` is `issue`, provide honest structured hints in the **`checks`** row (and optionally **`evidence`** for debugging):

- `finding_kind` (recommended): **`security`**, **`staleness`**, **`upstream_drift`**, **`custom`/blank`; drives **`concerns.security`** vs **`concerns.freshness`** together with **`custom_issue_policy`** (**[Concern derivation (`emitConcernsFromChecks`)](#aggregation-concerns-runner-v1)**).
- `severity` (optional, especially for security): label or numeric input for future advisory policy (**[CVE and advisory policy (v1)](#cve-and-advisory-policy-v1)**).

## CVE and advisory policy (v1)

Advisory-style audit items are **optional** and only where **coordinates** (or equivalent) are clear enough to query **honestly**.

- **Measurement vs judgment:** data sources report what applies to the tracked artifact (identifiers, versions, counts). **Aggregation** applies policy—for example **all applicable open advisories for the pinned release** vs a **time-bounded** view (e.g. only advisories published after a cutoff), plus a **minimum severity** band. “Critical only” may be too narrow for some ecosystems; prefer a **configurable floor** documented in the manifest.
- **Ambiguity:** missing or ambiguous identifiers → `inconclusive` for that item with a clear `detail`, never a silent `passed`.
- **Variance:** fetching and interpreting advisories is **implementation-specific**; **`outcome`** / **`finding_kind`** on **`checks`** rows and factual **`concerns`** stay comparable across components (**[Concern derivation (`emitConcernsFromChecks`)](#aggregation-concerns-runner-v1)**). Future **`review_result`** policy maps those facts at build-review time.

## Inputs (within each build directory)

- **Maintainer manifest (maintainer-edited, machine-readable):** `<slug>/audit.manifest.yaml` — minimal shape and examples: [Maintainer manifest (v1 minimal shape)](#maintainer-manifest-v1-minimal-shape). Keep this file concise and scalar-oriented for audits. Maintainers edit it in git; Phase 1 runners persist `review.result.json` only (they do not parse or rewrite the manifest).
- **Repository review policy (maintainer-edited, optional):** `review/review-policy.yaml` at the repo root — flat single-line scalars only (same mechanical constraints as maintainer manifests; see [`review/README.md`](../review/README.md)). Used for repository-wide defaults that `<slug>/audit.sh` may resolve before falling back to constants in `src/review/audit-check-helpers/review-policy-defaults.sh`. **Precedence** for keys both files define (for example `installer_staleness_max_days` for `installer-validated-staleness`): **component manifest → `review/review-policy.yaml` → helper fallback**.
- **Machine-generated review output:** written beside the manifest in the same build directory; owned by the tool (timestamps, last run, evidence). Not hand-edited.

### Maintainer manifest (v1 minimal shape)

Manifest files use the pattern `builds/<build>/<slug>/audit.manifest.yaml` (same per-component subdirectory as **`install.sh`**). On disk the format is **YAML**; the **key–value structure** below is the same if expressed as **JSON**. Examples use JSON for compact, copy-pasteable packets. Long-form rationale belongs in **`<slug>/audit.sh`** comments or stays brief in the optional manifest **`notes`** scalar.

**Required**

| Field | Type | Purpose |
| ----- | ---- | ------- |
| `component` | string | **Canonical CSV token** for this component; must match the JSON `component` field. The manifest path is `builds/<build>/<slug>/audit.manifest.yaml` where **`<slug>`** is that token with hyphens mapped to underscores (same directory as `builds/<build>/<slug>/install.sh`). |

**Recommended**

| Field | Type | Purpose |
| ----- | ---- | ------- |
| `upstream_tracking` | string | Concise scalar about tracking mode (e.g. `apt`, pinned tarball, version API). Elaborate in **`<slug>/audit.sh`** comments if needed. |

**Optional**

| Field | Type | Purpose |
| ----- | ---- | ------- |
| `last_known_upstream` | string | Plain maintainer-known upstream value for drift checks (interpretation stays in **`<slug>/audit.sh`**). |
| `installer_validated` | string | When someone last validated the installer path; **`YYYY-MM-DD`** recommended. |
| `installer_staleness_max_days` | string | Optional per-component override (days) for `installer-validated-staleness`; repository default in [`review/review-policy.yaml`](../review/review-policy.yaml), then resolver fallback in `src/review/audit-check-helpers/review-policy-defaults.sh`. |
| `notes` | string | Short scalar note when needed; longer narrative belongs in **`<slug>/audit.sh`** comments. |

**Examples (JSON packets; valid as the same mapping in YAML)**

Minimal passable manifest for a versioned runtime:

```json
{
  "component": "node",
  "upstream_tracking": "nodejs.org LTS installer / version index",
  "last_known_upstream": "22.14.0",
  "installer_validated": "2026-04-01",
  "notes": "Pin compares against Node LTS index only."
}
```

Thin manifest when upstream comparison is weak or N/A:

```json
{
  "component": "essentials",
  "upstream_tracking": "apt metapackage and npm global packages",
  "notes": "Upstream compare N/A for metapackage stack."
}
```

### Paths and filenames (v1)

Review-side artefacts live in a per-component subdirectory `builds/<build>/<slug>/`, using **`<slug>`** (hyphens → underscores) — the **same directory** as the component **`install.sh`** sourced by dispatch. Short basenames (`install.sh`, `audit.sh`, `audit.manifest.yaml`, `review.result.json`) inside the subdirectory replace the older build-root `install_*.sh` layout and flat `<slug>_audit.sh` / `<slug>_review.*` files ([Component enumeration (v1): dispatch-aligned](#component-enumeration-v1-dispatch-aligned)).

| Role | Path |
| ---- | ---- |
| Audit script | `builds/<build>/<slug>/audit.sh` |
| Maintainer manifest (maintainer-edited, machine-readable) | `builds/<build>/<slug>/audit.manifest.yaml` |
| Persisted review result JSON ([component artefact](#review-result-json-component-artifact-v1); runner-written) | `builds/<build>/<slug>/review.result.json` |
| Repository review policy (optional flat defaults; see [Inputs](#inputs-within-each-build-directory)) | `review/review-policy.yaml` |

Examples: `builds/dev-js/node/install.sh`, `builds/dev-js/node/audit.manifest.yaml`, `builds/dev-js/node/review.result.json` for component `node` in build `dev-js`. A CSV entry `mysql-client` would use `builds/<build>/mysql_client/install.sh` alongside `builds/<build>/mysql_client/audit.sh`, and (when present) `builds/<build>/mysql_client/audit.manifest.yaml` / `builds/<build>/mysql_client/review.result.json`.

**Version control (v1 repo policy):** Persisted `builds/<build>/<slug>/review.result.json` files are **tracked in git** when present (last known review state in-tree). Do not gitignore them globally or per-build. Maintainer files `builds/<build>/<slug>/audit.manifest.yaml` are tracked when present.

**Maintainer commands:** From repo root, **`./review/component-review.sh`** (Phase 1; component review). **`./review/build-review.sh`** (Phase 2; full **build review** loop—when shipped). Maintainer-facing documentation for the automated review lives in [`review/README.md`](../review/README.md). **Invocation** entrypoints for review live under **`review/`**; shared **implementation** (sourced libraries, subprocess **`audit-checks/`** modules, future orchestrator body) lives under **`src/review/`**.

## Checks (component decides what runs)

**v1 implementation:** Land the **Phase 1** **`audit-checks/`** filenames in [Audit-check filenames (v1, signal-first)](#audit-check-filenames-v1-signal-first) plus shared **`audit-check-helpers/`** (HTTP timeouts, retries, parsing). **Add more** as components need them—the **library** is expected to grow.

Audit **item kinds** below are **examples**—not every component implements every kind:

1. **Advisories / CVE-style** signals where coordinates and policy allow (see [CVE and advisory policy (v1)](#cve-and-advisory-policy-v1)).
2. **Upstream version** against `last_known_upstream` when discoverable—the audit script chooses among `upstream-exact-match.sh`, `upstream-semver-drift.sh`, distro-aware helpers in `audit-check-helpers/`, or **`custom`** ([Version strings](#version-strings-manifest-vs-script-v1-decision)).
3. **Staleness:** `installer_validated` older than a configurable threshold (hygiene; often weak for `apt`-style installs unless skipped or down-ranked).
4. `custom`: anything that does not fit a shared helper; still uses the same `outcome` vocabulary.

Components that cannot run a given kind of item should **`skip`** or omit it per [Audit item outcomes (normalized)](#audit-item-outcomes-normalized); use **`outcome` `inconclusive`** with an honest **`detail`** when measurement cannot conclude—not a silent **pass** disguised as **clean**.

## Components and scripts

In the same **`builds/<build>/<slug>/`** directory as **`install.sh`**, a **`audit.sh`** **may** exist ([Component enumeration (v1): dispatch-aligned](#component-enumeration-v1-dispatch-aligned)). When it does, it runs measurement only: compose **`checks`** (including per-check `evidence` where useful), declare **`required_check_ids`** (and optional **`custom_issue_policy`**), emit [Audit measurement stdout (Phase 1)](#audit-measurement-stdout-phase-1) on **stdout**, **exit 0** (**[Audit model (measurement only)](#audit-model-measurement-only)**). **`review/component-review.sh`** derives **`concerns`** and persists the merged artefact. When **`audit.sh`** is absent, **build review** **soft skips** (**[policy](#v1-skip-policy-soft-build-review)**).

Expect **heavy per-component variance** (URLs, versioning schemes, ecosystems).

## Shared abstraction (v1 scope)


| Layer                                              | Responsibility                                                                                                                                                                                                                                     |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Build review (specified)**                       | For a build directory, walk **`VALID_INSTALL_COMPONENTS`** in order; **soft skip** entries with no **`<slug>/audit.sh`** ([policy](#v1-skip-policy-soft-build-review)); run **component reviews** for the rest; persist **artefacts** only (no installs). **CLI (planned):** **`review/build-review.sh`**; orchestrator **implementation** under **`src/review/`** (Phase 2).                                                                                                                              |
| **Component review (Phase 1)**                         | **`review/component-review.sh`** invokes **`<slug>/audit.sh`**, validates measurement and merged artefacts, persists **`<slug>/review.result.json`**, optional acknowledgement (**[Runner validation](#runner-validation-phase-1)**). **`<slug>/audit.manifest.yaml`** is typically read **only by the audit**; concise maintainer context lives there or in **`<slug>/audit.sh`** comments. |
| **Audit checks + helpers** | **`src/review/audit-checks/`** … shared **measurement** only (**[Audit helper library](#audit-helper-library-shared-measurement)**). Do not set verdict/policy-view fields or **`concerns`**. |
| **Concern derivation (`emitConcernsFromChecks`)** | **`checks-rollup.sh`** / **`checks-rollup.jq`** — consumes **`checks`**, **`required_check_ids`**, **`custom_issue_policy`**; attaches **`concerns`** in **`component-review.sh`** ([Measurement → concerns interface](#measurement-concerns-interface-runner-v1)). |
| **`<slug>/audit.sh`** | Composes measurement, fills **`checks`** (with per-check `evidence` where needed), emits **`required_check_ids`** on stdout (**[Audit measurement stdout (Phase 1)](#audit-measurement-stdout-phase-1)**). Does **not** emit **`concerns`** or **`review_result`**. |


**v1 scope:** This spec defines **build review** behaviour (loop, skips, orchestration exit codes) as the **contract** for **`build-review.sh`**, and **component review** JSON + validation as the **contract** for **`component-review.sh`**. **Implementation** may ship **component-review** before **build-review** ([Implementation rollout](#implementation-rollout)). **Build-level** roll-up (a single **0–2** outcome—or richer summary—for the whole build), **component audit opt-out** / policy exclusions beyond **soft skip**, and **strict** “every CSV entry must have **`<slug>/audit.sh`**” modes are **out of scope** for this document.

## Review result JSON (component artefact, v1) {#review-result-json-component-artifact-v1}

v1 persists **`<slug>/review.result.json`** whenever **`component-review`** completes (**[Paths and filenames (v1)](#paths-and-filenames-v1)**). Entries **without an audit script** use the **soft skip** rule (**[v1 skip policy](#v1-skip-policy-soft-build-review)**) and produce **no** result JSON.

Facts live on disk: **`checks`** (with per-check **`evidence`** where applicable), runner-derived **`concerns`**, and merge metadata (**`build`**, **`component`**, **`review_completed`**, **`component_reviewer_version`**). Verdict/policy views (**`review_result`**, **`summary`**, **`reasons`**) belong to planned **build-level** output—not this file (**[Facts vs policy views](#facts-vs-policy-views)**).

**Naming:** **Review result JSON** (**result JSON**). Path `builds/<build>/<slug>/review.result.json`.

### Top-level fields (required)


| Field | Type | Purpose |
| ----- | ---- | ------- |
| `component_reviewer_version` | number | Exactly **1**. |
| `build` | string | Build directory (first argument to **`./wsl-builder.sh`**). |
| `component` | string | Canonical CSV token. |
| `review_completed` | string | **`YYYY-MM-DDThh:mm:ssZ`** UTC. |
| `checks` | array | [Normalized outcomes](#audit-item-outcomes-normalized). Rows may include per-check `evidence` objects with snake_case keys. |
| `concerns` | object | **Exactly `security`, `freshness`, `skipped`, `incomplete`** — booleans (**[Component concerns](#component-concerns-four-factual-dimensions)**). |

**Forbidden on the persisted artefact:** `required_check_ids`, `custom_issue_policy`, top-level `evidence`, `review_result`, `review_result_label`, `review_concerns`, `reasons`, `summary`.

Emit **`checks`** explicitly (array; empty allowed). Use per-check `evidence` when helpful.

### Top-level extras (runner / future)

Validators **today** forbid unknown verdict keys; reserve extra machine keys until a revision widens schema.

### Example (illustrative)

```json
{
  "component_reviewer_version": 1,
  "build": "dev-js",
  "component": "node",
  "review_completed": "2026-05-05T13:30:45Z",
  "concerns": {
    "security": false,
    "freshness": false,
    "skipped": false,
    "incomplete": false
  },
  "checks": [
    {
      "audit_check_id": "advisories",
      "outcome": "passed",
      "detail": "No advisories above the configured threshold.",
      "evidence": {
        "advisories_checked": 12
      }
    }
  ]
}
```

An **`issue`** row should normally include **`finding_kind`** / optional **`severity`**, for example **`{ ... "finding_kind":"security","severity":"high" }`**.

Merged JSON must satisfy **`validateMergedResultJson`** (**[Persisted artefact validation](#persisted-artefact-validation-merged-json)**).

## Network and flake policy (v1)

v1 adopts a **middle-ground** policy: enough resilience for CI and flaky networks without full “strict live / offline modes” or circuit-breaking.

- **Retries:** A **small fixed budget** (for example **2–3** attempts) with **short backoff**, only for **clearly transient** failures (timeouts, connection reset, **HTTP 5xx**). Do **not** use this budget to paper over deterministic errors (for example **404**, auth/`401`/`403`, or bad request/`400`).
- **Timeouts:** Use **per–audit-item** (or per logical fetch class) timeouts so one slow upstream does not dominate the whole review. Shared defaults in helpers are fine; components may tighten or relax per check.
- **Outcomes:** After retries are exhausted, a still-transient or inconclusive network story maps the affected item to **`inconclusive`** with an honest **`detail`** (see [Audit item outcomes (normalized)](#audit-item-outcomes-normalized)).
- **Concerns derivation:** **`inconclusive`** on **required** **`audit_check_ids`** ⇒ **`concerns.incomplete`** (**true**); non-required rows may remain **`inconclusive`** without that flag (**[Concern derivation (`emitConcernsFromChecks`)](#aggregation-concerns-runner-v1)**).

**Shared helper behaviour (v1, `httpGetWithRetry`):** The implementation in `src/review/audit-check-helpers/http-get-with-retry.sh` applies the bullets above as follows: **up to 3 attempts** (within the **2–3** budget), **incremental short backoff** (sleep **1** second before the second attempt, then increase the delay by **1** second before each further retry), and retries **only** when the response is **HTTP 5xx** or when **`curl` produces no usable status** (timeouts, connection failures, resets)—concretely, the script treats **`curl --write-out '%{http_code}'` value `000`** in that case alongside **5xx**. It **does not** retry **4xx** (including **404**, **400**, **401**/**403**). Each attempt uses **`curl --max-time`**; the helper’s default is **30** seconds when the caller passes only a URL (optional second argument overrides). Callers such as **`http-json-upstream-version.sh`** may pass a per-check **`max_time`** as their fourth argument so one slow upstream stays bounded per [Timeouts](#network-and-flake-policy-v1) above.
