#!/usr/bin/env bash
# Read-only probe for /pulse. Never writes, never pushes.
# Prints "unavailable — <reason>" rather than an empty section, so a failure
# is never mistaken for "there is nothing here".
set +e

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)
PR_FILTER="$HERE/pulse-pr.jq"
PR_FIELDS='number,title,isDraft,mergeable,reviewDecision,statusCheckRollup,headRefName'
PR_LIMIT=50

# 1. Code state. `git rev-parse` works in subdirectories and linked worktrees,
#    where a `.git` directory test does not.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  root=$(git rev-parse --show-toplevel 2>/dev/null)
  [ -n "$root" ] && cd "$root" 2>/dev/null

  branch=$(git --no-pager branch --show-current 2>/dev/null)
  echo "### branch";         printf '%s\n' "${branch:-(detached HEAD)}"
  echo "### uncommitted";    git --no-pager status -sb 2>/dev/null | head -20
  echo "### recent commits"; git --no-pager log --oneline -10 2>/dev/null

  echo "### open PRs"
  if ! command -v gh >/dev/null 2>&1; then
    echo "unavailable — gh (GitHub CLI) is not installed"
  else
    pr_json=$(gh pr list --state open --limit "$PR_LIMIT" --json "$PR_FIELDS" 2>&1)
    pr_rc=$?
    if [ "$pr_rc" -ne 0 ]; then
      echo "unavailable — gh failed: $(printf '%s' "$pr_json" | tr '\n' ' ' | cut -c1-160)"
    elif ! command -v jq >/dev/null 2>&1; then
      echo "(jq not installed — plain list, no CI or review state)"
      gh pr list --state open --limit "$PR_LIMIT" 2>/dev/null
    elif [ ! -r "$PR_FILTER" ]; then
      echo "(pulse-pr.jq not found beside pulse.sh — plain list, no CI or review state)"
      gh pr list --state open --limit "$PR_LIMIT" 2>/dev/null
    else
      count=$(printf '%s' "$pr_json" | jq 'length' 2>/dev/null)
      if [ -z "$count" ]; then
        echo "unavailable — could not parse gh output as JSON"
      else
        if [ "$count" -ge "$PR_LIMIT" ]; then
          echo "count: ${PR_LIMIT}+ (showing first $PR_LIMIT)"
        else
          echo "count: $count"
        fi
        rendered=$(printf '%s' "$pr_json" | jq -r --arg cur "$branch" -f "$PR_FILTER" 2>&1)
        render_rc=$?
        if [ "$render_rc" -ne 0 ]; then
          echo "unavailable — could not render PR state: $(printf '%s' "$rendered" | head -1)"
        else
          printf '%s\n' "$rendered"
        fi
      fi
    fi

    merged=$(gh pr list --state merged --limit 5 2>&1)
    merged_rc=$?
    echo "### recently merged"
    if [ "$merged_rc" -ne 0 ]; then
      echo "unavailable — gh failed"
    else
      printf '%s\n' "$merged"
    fi
  fi
fi

# 2. Decision logs — recent slice only, never whole files
for f in DECISIONS.md CHANGELOG.md NOTES.md ROADMAP.md; do
  if [ -f "$f" ]; then echo "### $f (top)"; head -20 "$f"; fi
done

# Every matching dir, not just the first — repos carry more than one plans dir.
# Two levels deep, so a plans dir split into subfolders is still found.
for d in plans* docs decisions notes; do
  found=$(ls -t "$d"/*.md "$d"/*/*.md 2>/dev/null)
  if [ -n "$found" ]; then
    echo "### recent notes in $d/ (names only)"
    printf '%s\n' "$found" | head -6
  fi
done

# 2b. Open items inside the most recent notes — marker lines only, never whole files
recent=$(ls -t plans*/*.md plans*/*/*.md docs/*.md docs/*/*.md \
              decisions/*.md decisions/*/*.md notes/*.md notes/*/*.md 2>/dev/null | head -3)
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
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "### recently changed"; ls -t 2>/dev/null | head -15
fi
