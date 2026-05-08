# Runner validation for merged review result JSON (spec: persisted component artefact — facts bundle).
# Caller must source src/print.sh (printError) before sourcing this file.

printMergedValidationFailure() {
    printError "Merged review JSON failed runner validation (see spec: Runner validation after audit (v1))"
    if [ -n "${1:-}" ]; then
        printError "${1}"
    fi
}

printAuditMeasurementFailure() {
    printError "Audit stdout failed measurement JSON validation (see spec: Audit measurement stdout, Phase 1)"
    if [ -n "${1:-}" ]; then
        printError "${1}"
    fi
}

# Validate audit stdout (before merge): measurement-only envelope; must not carry verdict/policy-view fields or concerns.
validateAuditMeasurementJson() {
    local audit="$1"
    local jq_err
    jq_err=$(mktemp)
    trap 'rm -f "${jq_err}"' RETURN
    # shellcheck disable=SC2016
    if jq -e '
        (type == "object") and
        (.component_reviewer_version | type == "number") and (.component_reviewer_version == 1) and
        (.checks | type == "array") and
        (.evidence | type == "object") and
        (.required_check_ids | type == "array") and
          (.required_check_ids | map(type == "string") | all) and
        (.custom_issue_policy // {} | type == "object") and
        (has("review_result") | not) and (has("review_result_label") | not) and
        (has("review_concerns") | not) and (has("concerns") | not) and
        (has("reasons") | not) and (has("summary") | not) and
        (has("build") | not) and (has("component") | not) and (has("review_completed") | not)
    ' <<<"${audit}" >/dev/null 2>"${jq_err}"; then
        return 0
    fi
    printAuditMeasurementFailure "$(cat "${jq_err}")"
    return 1
}

# Validate persisted merged JSON: runner fields + checks + evidence + concerns; no verdict or policy-view fields.
validateMergedResultJson() {
    local merged="$1"
    local jq_err
    jq_err=$(mktemp)
    trap 'rm -f "${jq_err}"' RETURN
    # shellcheck disable=SC2016
    if jq -e '
        (type == "object") and
        (.component_reviewer_version | type == "number") and (.component_reviewer_version == 1) and
        (.build | type == "string") and ((.build | length) > 0) and
        (.component | type == "string") and ((.component | length) > 0) and
        (.review_completed | type == "string") and
          (.review_completed | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")) and
        (.checks | type == "array") and
        (.evidence | type == "object") and
        (.concerns | type == "object") and
        (.concerns | keys | sort) == ["freshness","incomplete","security","skipped"] and
        (.concerns.security | type == "boolean") and
        (.concerns.freshness | type == "boolean") and
        (.concerns.skipped | type == "boolean") and
        (.concerns.incomplete | type == "boolean") and
        (has("required_check_ids") | not) and (has("custom_issue_policy") | not) and
        (has("review_result") | not) and (has("review_result_label") | not) and
        (has("review_concerns") | not) and
        (has("reasons") | not) and (has("summary") | not)
    ' <<<"${merged}" >/dev/null 2>"${jq_err}"; then
        return 0
    fi
    printMergedValidationFailure "$(cat "${jq_err}")"
    return 1
}
