#!/usr/bin/env bash
# Advisory review for the shellcheck component (dev-bash build).
#
# Aggregation is inlined here until delivery phase 3 shared helper (spec: Measurement and
# aggregation interface v1). Policy: exactly one measurement check id `shellcheck_cli`.
# - If the shellcheck CLI is missing → outcome inconclusive → top-level review_result 3.
# - If present (version parsed or observable) → outcome passed → top-level review_result 0.
#
# Stdout: one JSON object line (spec: Runner validation after audit v1). Stderr: diagnostics only.
# Does not install packages; if jq is missing, component-review.sh fails before this script runs.

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "audit_shellcheck.sh: jq is required to emit JSON; see CONTRIBUTING.md (Automated builds review tooling)." >&2
    exit 1
fi

if ! command -v shellcheck >/dev/null 2>&1; then
    jq -cn '
      {
        "component_reviewer_version": 1,
        "review_result": 3,
        "summary": "shellcheck review incomplete: CLI not on PATH.",
        "reasons": ["shellcheck binary was not found on PATH."],
        "checks": [{
          "id": "shellcheck_cli",
          "outcome": "inconclusive",
          "detail": "shellcheck is not installed or not on PATH; run the shellcheck component install first."
        }],
        "evidence": {}
      }'
    exit 0
fi

shellcheck_version=$(shellcheck --version 2>/dev/null | sed -n 's/^version:[[:space:]]*//p' | head -n1 || true)
if [ -z "${shellcheck_version}" ]; then
    shellcheck_version="(no version line from shellcheck --version)"
fi

jq -cn \
    --arg ver "${shellcheck_version}" \
    '{
      "component_reviewer_version": 1,
      "review_result": 0,
      "summary": "shellcheck CLI is available.",
      "reasons": [],
      "checks": [{
        "id": "shellcheck_cli",
        "outcome": "passed",
        "detail": ("Reported package/version line: " + $ver)
      }],
      "evidence": {
        "shellcheck_reported_version": $ver
      }
    }'
exit 0
