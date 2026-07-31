# Renders one line per open PR: number, title, and the state that answers
# "why is this blocked". Expects `--arg cur <current branch>`.
#
# Never says "clean" for a PR with no checks — "no checks reported" means
# nothing ran, which is not the same as anything passing.

def names($set): $set | map(.name // .context // "check") | .[0:2] | join(", ");
def overflow($set): if ($set | length) > 2 then " +\(($set | length) - 2)" else "" end;

def ci_state:
  (.statusCheckRollup // []) as $c
  | ($c | map(select((.conclusion // .state // "")
        | test("FAILURE|ERROR|TIMED_OUT|CANCELLED|STARTUP_FAILURE")))) as $bad
  | ($c | map(select((.conclusion // .state // "")
        | test("ACTION_REQUIRED|STALE")))) as $att
  | ($c | map(select(((.status // "") | test("IN_PROGRESS|QUEUED|WAITING|PENDING"))
        or ((.state // "") == "PENDING")))) as $run
  | if   ($bad | length) > 0 then "CI failing (" + names($bad) + overflow($bad) + ")"
    elif ($att | length) > 0 then "CI needs attention (" + names($att) + overflow($att) + ")"
    elif ($run | length) > 0 then "CI running"
    elif ($c   | length) > 0 then "CI green"
    else "no checks reported"
    end;

def merge_state:
  if   .mergeable == "CONFLICTING" then "CONFLICTS with base"
  elif .mergeable == "UNKNOWN"     then "mergeability pending"
  else empty end;

def review_state:
  if   .reviewDecision == "CHANGES_REQUESTED" then "changes requested"
  elif .reviewDecision == "APPROVED"          then "approved"
  elif .reviewDecision == "REVIEW_REQUIRED"   then "needs review"
  else empty end;

# Checked-out branch first — it is the PR most likely being worked on.
sort_by([(if .headRefName == $cur then 0 else 1 end), -.number])
| .[]
| [ (if .isDraft then "draft" else empty end), ci_state, merge_state, review_state ] as $f
| "#\(.number) \(.title)"
  + (if .headRefName == $cur and $cur != "" then " [current branch]" else "" end)
  + " — " + ($f | join(" · "))
