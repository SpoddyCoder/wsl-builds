# Aggregation helper program (checks-rollup.jq; spec: Aggregation helper (shared, v1), Aggregating to review_result).
# Expects --argjson checks, --argjson requiredIds, --argjson policy (-n null input).
# Emits review_result, review_result_label, review_concerns, reasons, summary per spec.

def label_v1($code):
  if $code == 0 then "Checks ran; no issues found."
  elif $code == 1 then "Checks ran; one or more concerns found."
  elif $code == 2 then "Checks did not complete successfully (runner error, upstream unreachable, unsupported case, unknown)."
  else
    "Checks did not complete successfully (runner error, upstream unreachable, unsupported case, unknown)."
  end;

def policy_routes_by_audit_check_id:
  ($policy.routes_by_audit_check_id // {});

def is_issue(c):
  (c.outcome == "issue");

# Internal slots (never emitted): not_issue, security, freshness, excluded, unrouted
def route_slot(c):
  if (is_issue(c) | not) then "not_issue"
  else
    (c.finding_kind // "") as $fk
    | (policy_routes_by_audit_check_id)[c.audit_check_id] as $pr
    | if $fk == "security" then "security"
      elif $fk == "staleness" or $fk == "upstream_drift" then "freshness"
      elif $fk == "custom" or $fk == "" then
        if $pr == "security" then "security"
        elif $pr == "freshness" then "freshness"
        elif $pr == "none" then "excluded"
        else "unrouted"
        end
      else
        if $pr == "security" then "security"
        elif $pr == "freshness" then "freshness"
        elif $pr == "none" then "excluded"
        else "unrouted"
        end
      end
  end;

def missing_required:
  [ $requiredIds[] | select(. as $rid | ($checks | map(select(.audit_check_id == $rid)) | length) == 0) ];

def inconclusive_required:
  [ $requiredIds[] | select(. as $rid |
      ($checks | map(select(.audit_check_id == $rid and .outcome == "inconclusive")) | length) > 0) ];

def any_unrouted:
  any($checks[]; route_slot(.) == "unrouted");

def has_security_concern:
  any($checks[]; route_slot(.) == "security");

def has_freshness_concern:
  any($checks[]; route_slot(.) == "freshness");

def reasons_for_incomplete_missing:
  [ missing_required[] | "Required check id \"" + . + "\" has no row in checks." ];

def reasons_for_incomplete_inconclusive:
  [ $requiredIds[] as $rid | $checks[] | select(.audit_check_id == $rid and .outcome == "inconclusive")
    | "Required check \"" + .audit_check_id + "\" is inconclusive: " + (.detail // "") ];

def reasons_unrouted:
  [ $checks[] | select(is_issue(.) and route_slot(.) == "unrouted")
    | "Issue check \"" + .audit_check_id + "\" has no top-level classification (set finding_kind or routes_by_audit_check_id)." ];

def reasons_security:
  [ $checks[] | select(is_issue(.) and route_slot(.) == "security")
    | "Security-class issue: " + .audit_check_id + " — " + (.detail // "") ];

def reasons_freshness:
  [ $checks[] | select(is_issue(.) and route_slot(.) == "freshness")
    | "Staleness or drift issue: " + .audit_check_id + " — " + (.detail // "") ];

def concerns_false:
  { "security": false, "freshness": false };

if ((missing_required | length) > 0) or ((inconclusive_required | length) > 0) then
  (reasons_for_incomplete_missing + reasons_for_incomplete_inconclusive) as $rs |
  {
    review_result: 2,
    review_result_label: label_v1(2),
    review_concerns: concerns_false,
    reasons: $rs,
    summary: "Review incomplete: required check(s) missing or inconclusive."
  }
elif any_unrouted then
  reasons_unrouted as $ru |
  {
    review_result: 2,
    review_result_label: label_v1(2),
    review_concerns: concerns_false,
    reasons: $ru,
    summary: "Review incomplete: one or more issue checks lack top-level classification."
  }
elif (has_security_concern or has_freshness_concern) then
  (reasons_security + reasons_freshness) as $rs |
  (if (has_security_concern and has_freshness_concern) then
    "Security and freshness concern(s) detected."
  elif has_security_concern then
    "Security-class issue(s) detected."
  else
    "Staleness or upstream drift issue(s) detected."
  end) as $sm |
  {
    review_result: 1,
    review_result_label: label_v1(1),
    review_concerns: {
      "security": has_security_concern,
      "freshness": has_freshness_concern
    },
    reasons: $rs,
    summary: $sm
  }
else
  {
    review_result: 0,
    review_result_label: label_v1(0),
    review_concerns: concerns_false,
    reasons: [],
    summary: "All checks passed or carried only skipped/non-issue outcomes."
  }
end
