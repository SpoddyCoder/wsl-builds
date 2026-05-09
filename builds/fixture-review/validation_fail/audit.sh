#!/usr/bin/env bash
# Review-fixture audit: validation-fail scenario (automated review testing only).
#
# Deliberately emits a forbidden top-level "summary" field on audit stdout. The runner
# (component-review.sh -> validateAuditMeasurementJson) must reject this packet, exit
# non-zero, and never create or overwrite <slug>/review.result.json. No tracked result
# file exists for this scenario.
set -euo pipefail

########################################################
# Emit Invalid Measurement JSON (intentional)
#
printf '%s\n' '{"component_reviewer_version":1,"checks":[],"required_check_ids":[],"summary":"forbidden on audit stdout"}'
