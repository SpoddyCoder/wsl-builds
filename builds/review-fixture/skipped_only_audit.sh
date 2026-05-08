#!/usr/bin/env bash
# Review-fixture audit: skipped-only scenario (automated review testing only).
#
# One skipped row; no required check ids and no issues.
# Expected runner-derived concerns: { skipped: true, others: false }.
set -euo pipefail

printf '%s\n' '{"component_reviewer_version":1,"checks":[{"audit_check_id":"opt","outcome":"skipped","detail":"Not applicable for this fixture."}],"required_check_ids":[]}'
