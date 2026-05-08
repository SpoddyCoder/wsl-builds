#!/usr/bin/env bash
# Review-fixture audit: incomplete-required scenario (automated review testing only).
#
# req-a present but inconclusive (forces incomplete); req-b is required but missing from checks
# (also forces incomplete). Expected runner-derived concerns: { incomplete: true, others: false }.
set -euo pipefail

printf '%s\n' '{"component_reviewer_version":1,"checks":[{"audit_check_id":"req-a","outcome":"inconclusive","detail":"Could not determine; required row inconclusive."}],"required_check_ids":["req-a","req-b"]}'
