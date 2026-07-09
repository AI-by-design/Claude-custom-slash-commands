#!/usr/bin/env bash
set +e

# 1. Code state
if [ -d .git ]; then
  echo "### branch";         git --no-pager branch --show-current 2>/dev/null
  echo "### uncommitted";    git --no-pager status -sb 2>/dev/null | head -20
  echo "### recent commits"; git --no-pager log --oneline -10 2>/dev/null
  if command -v gh >/dev/null 2>&1; then
    echo "### open PRs";        gh pr list --state open --limit 10 2>/dev/null
    echo "### recently merged"; gh pr list --state merged --limit 5 2>/dev/null
  fi
fi

# 2. Decision logs — recent slice only, never whole files
for f in DECISIONS.md CHANGELOG.md NOTES.md ROADMAP.md; do
  if [ -f "$f" ]; then echo "### $f (top)"; head -20 "$f"; fi
done
for d in plans docs decisions notes; do
  if ls "$d"/*.md >/dev/null 2>&1; then
    echo "### recent notes in $d/ (names only)"; ls -t "$d"/*.md 2>/dev/null | head -6
    break
  fi
done

# 3. Fallback when there's no git
if [ ! -d .git ]; then
  echo "### recently changed"; ls -t 2>/dev/null | head -15
fi
