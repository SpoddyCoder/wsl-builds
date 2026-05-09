# review-fixture

**Automated review testing only.**

This build directory exists to drive deterministic scenarios for the **automated builds review** (run `./review/component-review.sh` from the repo root, e.g. `./review/component-review.sh review-fixture happy-path`) and the maintainer debug harness (`./review/review-debug.sh`). It is **not** a real environment build.

Each component token maps to one scenario:

| Token | Scenario | Expected `concerns` |
| ----- | -------- | ------------------- |
| `happy-path` | All required checks pass; no issues. | all `false` |
| `incomplete-required` | Required check `inconclusive` and a required id missing. | `incomplete: true` |
| `issue-routed` | One `security` and one `staleness` `issue` row. | `security: true`, `freshness: true` |
| `policy-none-route` | `custom` `issue` excluded via `custom_issue_policy.routes_by_audit_check_id`. | all `false` |
| `skipped-only` | One `skipped` row, nothing required. | `skipped: true` |
| `validation-fail` | Audit deliberately emits a forbidden top-level field. | runner exits non-zero, **no** result file written. |

Each scenario directory also includes `audit.manifest.yaml` (machine-readable scalar fixture metadata) and `audit.notes.md` (human scenario prose). Each `<slug>/audit.sh` emits one deterministic JSON object on stdout via `printf` (no jq, no network). Fixture audits do source `get-audit-check-id.sh` so `audit_check_id` values follow the same derivation path as real audits/debug checks. Persisted `<slug>/review.result.json` is tracked for the five valid scenarios; `validation-fail` deliberately has no tracked result file (the runner must not create one).

## Pointers

- Test catalog: [`test/README.md`](../../test/README.md) (Review-fixture suite).
- Maintainer overview: [`review/README.md`](../../review/README.md) (debug harness, fixture purpose).
- Normative contract: [`docs/automated-builds-review-v1-spec.md`](../../docs/automated-builds-review-v1-spec.md).

Do not rely on this build for real installs.
