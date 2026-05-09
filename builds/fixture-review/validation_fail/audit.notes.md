Deterministic offline scenario for validation failure behavior.

- The audit emits forbidden top-level `summary` on stdout to trigger measurement validation failure.
- Runner must exit non-zero and must not create or overwrite `validation_fail/review.result.json`.
- No tracked result file is expected for this scenario.
