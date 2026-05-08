#!/usr/bin/env bash
# Review-fixture audit: issue-routed scenario (automated review testing only).
#
# One issue with finding_kind=security and one with finding_kind=staleness, both required.
# Expected runner-derived concerns: { security: true, freshness: true, skipped: false, incomplete: false }.
set -euo pipefail

printf '%s\n' '{"component_reviewer_version":1,"checks":[{"audit_check_id":"sec","outcome":"issue","finding_kind":"security","severity":"high","detail":"Routed security issue."},{"audit_check_id":"fresh","outcome":"issue","finding_kind":"staleness","detail":"Routed freshness issue."}],"required_check_ids":["sec","fresh"]}'
