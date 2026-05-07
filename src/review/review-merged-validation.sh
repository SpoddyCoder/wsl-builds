# Runner validation for merged review result JSON (spec: Runner validation after audit (v1),
# Review result JSON (v1) required top-level fields, Runner-owned additions).
# Caller must source src/print.sh (printError) before sourcing this file.

reviewPrintMergedValidationFailure() {
    printError "Merged review JSON failed runner validation (see spec: Runner validation after audit (v1))"
    if [ -n "${1:-}" ]; then
        printError "${1}"
    fi
}

# Validate merged JSON (audit stdout + runner fields) per spec required top-level fields
# and review_result 0–2 integer. Prints errors via printError on failure.
reviewValidateMergedResultJson() {
    local merged="$1"
    local jq_err
    jq_err=$(mktemp)
    trap 'rm -f "${jq_err}"' RETURN
    if jq -e '
        (type == "object") and
        (.component_reviewer_version | type == "number") and (.component_reviewer_version == 1) and
        (.build | type == "string") and ((.build | length) > 0) and
        (.component | type == "string") and ((.component | length) > 0) and
        (.review_completed | type == "string") and
          (.review_completed | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")) and
        (.review_result | type == "number") and (.review_result >= 0 and .review_result <= 2) and
          (.review_result == ((.review_result | floor))) and
        (.review_result_label | type == "string") and
          (
            (.review_result == 0 and .review_result_label == "Checks ran; no issues found.") or
            (.review_result == 1 and .review_result_label == "Checks ran; one or more concerns found.") or
            (.review_result == 2 and .review_result_label == "Checks did not complete successfully (runner error, upstream unreachable, unsupported case, unknown).")
          ) and
        (.review_concerns | type == "object") and
        (.review_concerns.security | type == "boolean") and
        (.review_concerns.freshness | type == "boolean") and
        (
          (.review_result == 0 and .review_concerns.security == false and .review_concerns.freshness == false) or
          (.review_result == 2 and .review_concerns.security == false and .review_concerns.freshness == false) or
          (.review_result == 1 and (.review_concerns.security == true or .review_concerns.freshness == true))
        ) and
        (.reasons | type == "array") and
          (.reasons | map(type == "string") | all)
    ' <<<"${merged}" >/dev/null 2>"${jq_err}"; then
        return 0
    fi
    reviewPrintMergedValidationFailure "$(cat "${jq_err}")"
    return 1
}
