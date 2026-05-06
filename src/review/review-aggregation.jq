# Aggregation helper program (spec: Aggregation helper (shared, v1), Aggregating to review_result).
# Expects --argjson checks, --argjson requiredIds, --argjson policy (-n null input).

def routes_by_id:
  ($policy.routes_by_check_id // {});

def is_issue(c):
  (c.outcome == "issue");

# Security / drift buckets use explicit finding_kind only (not custom routing table alone).
def route_slot(c):
  if (is_issue(c) | not) then "ok"
  elif ((c.finding_kind // "") == "security") then "one"
  elif ((c.finding_kind // "") == "staleness" or (c.finding_kind // "") == "upstream_drift") then "two"
  else
    ((routes_by_id)[c.id] // "none")
    | if . == "1" then "one" elif . == "2" then "two" else "none" end
  end;

def missing_required:
  [ $requiredIds[] | select(. as $rid | ($checks | map(select(.id == $rid)) | length) == 0) ];

def inconclusive_required:
  [ $requiredIds[] | select(. as $rid |
      ($checks | map(select(.id == $rid and .outcome == "inconclusive")) | length) > 0) ];

def slots:
  [ $checks[] | route_slot(.) ];

def any_slot(s): ((slots | index(s)) != null);

def reasons_for_three_missing:
  [ missing_required[] | "Required check id \"" + . + "\" has no row in checks." ];

def reasons_for_three_inconclusive:
  [ $requiredIds[] as $rid | $checks[] | select(.id == $rid and .outcome == "inconclusive")
    | "Required check \"" + .id + "\" is inconclusive: " + (.detail // "") ];

def reasons_unclassified:
  [ $checks[] | select(is_issue(.) and route_slot(.) == "none")
    | "Issue check \"" + .id + "\" has no top-level classification (set finding_kind or routes_by_check_id)." ];

def reasons_security:
  [ $checks[] | select(is_issue(.) and route_slot(.) == "one")
    | "Security-class issue: " + .id + " — " + (.detail // "") ];

def reasons_drift:
  [ $checks[] | select(is_issue(.) and route_slot(.) == "two")
    | "Staleness or drift issue: " + .id + " — " + (.detail // "") ];

if ((missing_required | length) > 0) or ((inconclusive_required | length) > 0) then
  (reasons_for_three_missing + reasons_for_three_inconclusive) as $rs |
  {
    review_result: 3,
    reasons: $rs,
    summary: "Review incomplete: required check(s) missing or inconclusive."
  }
elif any_slot("none") then
  reasons_unclassified as $ru |
  {
    review_result: 3,
    reasons: $ru,
    summary: "Review incomplete: one or more issue checks lack top-level classification."
  }
elif any_slot("one") then
  reasons_security as $rs |
  {
    review_result: 1,
    reasons: $rs,
    summary: "Security-class issue(s) detected."
  }
elif any_slot("two") then
  reasons_drift as $rs |
  {
    review_result: 2,
    reasons: $rs,
    summary: "Staleness or upstream drift issue(s) detected."
  }
else
  {
    review_result: 0,
    reasons: [],
    summary: "All checks passed or carried only skipped/non-issue outcomes."
  }
end
