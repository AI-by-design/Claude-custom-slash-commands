#!/usr/bin/env bash
# Read-only probe for /wrap. Works out where a session record belongs and
# reports it. Creates nothing, writes nothing, deletes nothing.
set +e

echo "### date"
date +%Y-%m-%d

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  root=$(git rev-parse --show-toplevel 2>/dev/null)
  [ -n "$root" ] && cd "$root" 2>/dev/null
fi

echo "### project root"
pwd

# A notes root is a directory holding .md files within two levels. Counting
# two deep matters: once a dir is split into conversations/ and
# implementation/, nothing sits directly inside it any more.
echo "### notes root candidates"
active=""
for d in plans* docs decisions notes; do
  [ -d "$d" ] || continue
  n=$(ls -1 "$d"/*.md "$d"/*/*.md 2>/dev/null | wc -l | tr -d ' ')
  printf '%s  (%s .md)\n' "$d" "$n"
  [ "$n" -gt 0 ] && active="$active $d"
done
[ -z "$active" ] && echo "(none found)"

# shellcheck disable=SC2086
set -- $active
NOTES_ROOT=""
echo "### resolved"
if [ "$#" -eq 0 ]; then
  NOTES_ROOT="plans"
  echo "plans/conversations"
  echo "note: no notes directory exists yet — it would be created"
elif [ "$#" -eq 1 ]; then
  NOTES_ROOT="$1"
  echo "$1/conversations"
else
  echo "AMBIGUOUS — more than one directory is in active use: $*"
  echo "note: ask which one before writing anything"
fi

if [ -n "$NOTES_ROOT" ]; then
  echo "### absolute target"
  echo "$(pwd)/$NOTES_ROOT/conversations"

  echo "### git status of target"
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "not a git repo — nothing to ignore"
  elif git check-ignore -q "$NOTES_ROOT" 2>/dev/null; then
    echo "ignored — safe, records stay out of git"
  else
    echo "NOT IGNORED — records here would be committable"
    echo "note: offer to add '$NOTES_ROOT/' to .gitignore before writing"
  fi

  echo "### existing records for today"
  today=$(date +%Y-%m-%d)
  found_today=$(ls -1 "$NOTES_ROOT"/conversations/"$today"-*.md 2>/dev/null)
  if [ -n "$found_today" ]; then
    printf '%s\n' "$found_today"
    echo "note: if one covers this session, update it instead of adding another"
  else
    echo "(none)"
  fi

  echo "### recent records"
  recent=$(ls -t "$NOTES_ROOT"/conversations/*.md 2>/dev/null | head -5)
  if [ -n "$recent" ]; then printf '%s\n' "$recent"; else echo "(none)"; fi

  # Show how the most recent record opens, so a new one matches house style
  newest=$(ls -t "$NOTES_ROOT"/conversations/*.md 2>/dev/null | head -1)
  if [ -n "$newest" ]; then
    echo "### house style — first 12 lines of the most recent record"
    head -12 "$newest"
  fi
fi
