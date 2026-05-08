#!/usr/bin/env bash
# Review-fixture audit: policy-none-route scenario (automated review testing only).
#
# Custom-kind issue routed to "none" via custom_issue_policy.routes_by_audit_check_id.
# Expected runner-derived concerns: all false (excluded from security/freshness without forcing incomplete).
set -euo pipefail

printf '%s\n' '{"component_reviewer_version":1,"checks":[{"audit_check_id":"opaque","outcome":"issue","finding_kind":"custom","detail":"Custom issue routed to none."}],"required_check_ids":["opaque"],"custom_issue_policy":{"routes_by_audit_check_id":{"opaque":"none"}}}'
