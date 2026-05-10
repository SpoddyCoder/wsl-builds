# Derives runner-owned concerns from checks[] + policy (spec: Policy views / facts bundle).
# Expects --argjson checks, --argjson requiredIds, --argjson policy (-n null input).
# Emits one object only: concerns with exactly security, freshness, skipped, incomplete (all booleans).

def policy_routes_by_audit_check_id:
  ($policy.routes_by_audit_check_id // {});

def is_issue(c):
  (c.outcome == "issue");

# Internal routing (never emitted): not_issue, security, freshness, excluded, unrouted
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

def any_skipped:
  any($checks[]; .outcome == "skipped");

def story_incomplete:
  ((missing_required | length) > 0)
  or ((inconclusive_required | length) > 0)
  or any_unrouted;

{
  "security": has_security_concern,
  "freshness": has_freshness_concern,
  "skipped": any_skipped,
  "incomplete": story_incomplete
}
