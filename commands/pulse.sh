#!/usr/bin/env bash
set +e

# 1. Code state
if [ -d .git ]; then
  echo "### branch";         git --no-pager branch --show-current 2>/dev/null
  echo "### uncommitted";    git --no-pager status -sb 2>/dev/null | head -20
  echo "### recent commits"; git --no-pager log --oneline -10 2>/dev/null
  if command -v gh >/dev/null 2>&1; then
    echo "### open PRs"
    if command -v jq >/dev/null 2>&1; then
      gh pr list --state open --limit 10 \
        --json number,title,isDraft,mergeable,reviewDecision,statusCheckRollup 2>/dev/null \
      | jq -r '
          def verdict($c):
            ($c | map(select((.conclusion // .state // "")
                             | test("FAILURE|ERROR|TIMED_OUT|CANCELLED|STARTUP_FAILURE")))) as $bad
          | ($c | map(select(((.status // "") | test("IN_PROGRESS|QUEUED|WAITING|PENDING"))
                             or ((.state // "") == "PENDING")))) as $run
          | if   ($bad | length) > 0 then
                 "CI failing (" + ($bad | map(.name // .context // "check") | .[0:2] | join(", "))
                 + (if ($bad | length) > 2 then " +\($bad | length - 2)" else "" end) + ")"
            elif ($run | length) > 0 then "CI running"
            elif ($c   | length) > 0 then "CI green"
            else empty end;
          .[]
          | (.statusCheckRollup // []) as $c
          | [ (if .isDraft then "draft" else empty end),
              verdict($c),
              (if .mergeable == "CONFLICTING" then "CONFLICTS with base" else empty end),
              (if   .reviewDecision == "CHANGES_REQUESTED" then "changes requested"
               elif .reviewDecision == "APPROVED"          then "approved"
               elif .reviewDecision == "REVIEW_REQUIRED"   then "needs review"
               else empty end)
            ] as $f
          | "#\(.number) \(.title) — "
            + (if ($f | length) > 0 then ($f | join(" · ")) else "clean" end)
        ' 2>/dev/null
    else
      gh pr list --state open --limit 10 2>/dev/null
    fi
    echo "### recently merged"; gh pr list --state merged --limit 5 2>/dev/null
  fi
fi

# 2. Decision logs — recent slice only, never whole files
for f in DECISIONS.md CHANGELOG.md NOTES.md ROADMAP.md; do
  if [ -f "$f" ]; then echo "### $f (top)"; head -20 "$f"; fi
done

# Every matching dir, not just the first — repos carry more than one plans dir
for d in plans* docs decisions notes; do
  if ls "$d"/*.md >/dev/null 2>&1; then
    echo "### recent notes in $d/ (names only)"; ls -t "$d"/*.md 2>/dev/null | head -6
  fi
done

# 2b. Open items inside the most recent notes — marker lines only, never whole files
recent=$(ls -t plans*/*.md docs/*.md decisions/*.md notes/*.md 2>/dev/null | head -3)
if [ -n "$recent" ]; then
  echo "### open items in recent notes"
  printf '%s\n' "$recent" | while IFS= read -r f; do
    hits=$(grep -nEi \
      -e '^[[:space:]]*-[[:space:]]\[[[:space:]]\]' \
      -e '\*\*[^*]*(status|next|open (decision|question)|blocked|awaiting|pending)[^*]*\*\*' \
      -e '^#+[[:space:]]+([0-9.]+[[:space:]]+)?(status|next|open (decision|question)|blocked)' \
      "$f" 2>/dev/null | head -4 | cut -c1-200)
    if [ -n "$hits" ]; then printf -- '-- %s\n%s\n' "$f" "$hits"; fi
  done
fi

# 3. Fallback when there's no git
if [ ! -d .git ]; then
  echo "### recently changed"; ls -t 2>/dev/null | head -15
fi
