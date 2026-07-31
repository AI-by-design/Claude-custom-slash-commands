#!/usr/bin/env bash
# Regression tests for /pulse. No network, no GitHub auth: `gh` is stubbed.
# Run: bash tests/run.sh
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$HERE/.." && pwd)
PULSE="$REPO/commands/pulse/pulse.sh"
FILTER="$REPO/commands/pulse/pulse-pr.jq"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0

check() { # name expected actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); printf '  ok   %s\n' "$1"
  else
    fail=$((fail + 1))
    printf '  FAIL %s\n    expected: %s\n    actual:   %s\n' "$1" "$2" "$3"
  fi
}

contains() { # name haystack needle
  if printf '%s' "$2" | grep -qF -- "$3"; then
    pass=$((pass + 1)); printf '  ok   %s\n' "$1"
  else
    fail=$((fail + 1))
    printf '  FAIL %s\n    expected to contain: %s\n    actual:   %s\n' "$1" "$3" "$(printf '%s' "$2" | head -5)"
  fi
}

render() { # json [current-branch] -> rendered lines
  printf '%s' "$1" | jq -r --arg cur "${2:-}" -f "$FILTER" 2>&1
}

pr() { # number title extra-json
  printf '{"number":%s,"title":"%s","isDraft":false,"mergeable":"MERGEABLE","reviewDecision":"","headRefName":"b%s",%s}' \
    "$1" "$2" "$1" "$3"
}

echo "PR state rendering"

check "no checks reported (empty rollup)" \
  "#1 t — no checks reported" \
  "$(render "[$(pr 1 t '"statusCheckRollup":[]')]")"

check "rollup field absent entirely" \
  "#1 t — no checks reported" \
  "$(render "[$(pr 1 t '"other":1')]")"

check "all checks green" \
  "#1 t — CI green" \
  "$(render "[$(pr 1 t '"statusCheckRollup":[{"name":"build","status":"COMPLETED","conclusion":"SUCCESS"}]')]")"

check "one failing check" \
  "#1 t — CI failing (test)" \
  "$(render "[$(pr 1 t '"statusCheckRollup":[{"name":"build","conclusion":"SUCCESS"},{"name":"test","conclusion":"FAILURE"}]')]")"

check "three failing checks show first two plus count" \
  "#1 t — CI failing (a, b +1)" \
  "$(render "[$(pr 1 t '"statusCheckRollup":[{"name":"a","conclusion":"FAILURE"},{"name":"b","conclusion":"FAILURE"},{"name":"c","conclusion":"TIMED_OUT"}]')]")"

check "checks in progress" \
  "#1 t — CI running" \
  "$(render "[$(pr 1 t '"statusCheckRollup":[{"name":"build","status":"IN_PROGRESS","conclusion":null}]')]")"

check "ACTION_REQUIRED is attention, not failure" \
  "#1 t — CI needs attention (approve)" \
  "$(render "[$(pr 1 t '"statusCheckRollup":[{"name":"approve","conclusion":"ACTION_REQUIRED"}]')]")"

check "STALE is attention" \
  "#1 t — CI needs attention (old)" \
  "$(render "[$(pr 1 t '"statusCheckRollup":[{"name":"old","conclusion":"STALE"}]')]")"

check "legacy context/state shaped check" \
  "#1 t — CI failing (ci/legacy)" \
  "$(render "[$(pr 1 t '"statusCheckRollup":[{"context":"ci/legacy","state":"FAILURE"}]')]")"

check "conflicting mergeable" \
  "#1 t — no checks reported · CONFLICTS with base" \
  "$(render '[{"number":1,"title":"t","isDraft":false,"mergeable":"CONFLICTING","reviewDecision":"","headRefName":"b1","statusCheckRollup":[]}]')"

check "UNKNOWN mergeable is pending, not silence" \
  "#1 t — no checks reported · mergeability pending" \
  "$(render '[{"number":1,"title":"t","isDraft":false,"mergeable":"UNKNOWN","reviewDecision":"","headRefName":"b1","statusCheckRollup":[]}]')"

check "changes requested" \
  "#1 t — no checks reported · changes requested" \
  "$(render '[{"number":1,"title":"t","isDraft":false,"mergeable":"MERGEABLE","reviewDecision":"CHANGES_REQUESTED","headRefName":"b1","statusCheckRollup":[]}]')"

check "draft plus every other flag" \
  "#1 t — draft · CI green · CONFLICTS with base · needs review" \
  "$(render '[{"number":1,"title":"t","isDraft":true,"mergeable":"CONFLICTING","reviewDecision":"REVIEW_REQUIRED","headRefName":"b1","statusCheckRollup":[{"name":"x","conclusion":"SUCCESS"}]}]')"

check "current branch sorts first and is labelled" \
  "#2 second [current branch] — no checks reported
#9 ninth — no checks reported" \
  "$(render '[{"number":9,"title":"ninth","isDraft":false,"mergeable":"MERGEABLE","reviewDecision":"","headRefName":"b9","statusCheckRollup":[]},{"number":2,"title":"second","isDraft":false,"mergeable":"MERGEABLE","reviewDecision":"","headRefName":"feature-x","statusCheckRollup":[]}]' feature-x)"

check "no current branch match keeps number order" \
  "#9 ninth — no checks reported
#2 second — no checks reported" \
  "$(render '[{"number":2,"title":"second","isDraft":false,"mergeable":"MERGEABLE","reviewDecision":"","headRefName":"b2","statusCheckRollup":[]},{"number":9,"title":"ninth","isDraft":false,"mergeable":"MERGEABLE","reviewDecision":"","headRefName":"b9","statusCheckRollup":[]}]' other)"

echo
echo "Probe behaviour"

mkrepo() { # dir -> initialised git repo
  mkdir -p "$1" && git -C "$1" init -q && git -C "$1" config user.email t@t.t \
    && git -C "$1" config user.name t && echo x > "$1/f.txt" \
    && git -C "$1" add -A && git -C "$1" commit -qm init
}

# stub gh: prints fixture JSON for --json calls, plain text otherwise
mkstub() { # dir mode
  mkdir -p "$1"
  if [ "$2" = "fail" ]; then
    printf '#!/bin/sh\necho "HTTP 401: Bad credentials" >&2\nexit 1\n' > "$1/gh"
  else
    cat > "$1/gh" <<'STUB'
#!/bin/sh
for a in "$@"; do
  if [ "$a" = "--json" ]; then
    echo '[{"number":7,"title":"stubbed","isDraft":false,"mergeable":"MERGEABLE","reviewDecision":"","headRefName":"nope","statusCheckRollup":[{"name":"build","conclusion":"FAILURE"}]}]'
    exit 0
  fi
done
echo "7	stubbed	nope	MERGED"
STUB
  fi
  chmod +x "$1/gh"
}

mkrepo "$TMP/repo" >/dev/null
mkstub "$TMP/bin" ok
PATHW="$TMP/bin:$PATH"

out=$(cd "$TMP/repo" && PATH="$PATHW" bash "$PULSE" 2>&1)
contains "renders stubbed PR state" "$out" "#7 stubbed — CI failing (build)"
contains "reports an exact open-PR count" "$out" "count: 1"

mkdir -p "$TMP/repo/deep/nested"
out=$(cd "$TMP/repo/deep/nested" && PATH="$PATHW" bash "$PULSE" 2>&1)
contains "works from a subdirectory (not just repo root)" "$out" "### branch"
contains "subdirectory still reaches PR state" "$out" "#7 stubbed"

git -C "$TMP/repo" worktree add -q "$TMP/wt" -b wt 2>/dev/null
out=$(cd "$TMP/wt" && PATH="$PATHW" bash "$PULSE" 2>&1)
contains "works inside a linked worktree" "$out" "### branch"

mkstub "$TMP/badbin" fail
out=$(cd "$TMP/repo" && PATH="$TMP/badbin:$PATH" bash "$PULSE" 2>&1)
contains "gh failure is explicit, never an empty section" "$out" "unavailable — gh failed"

out=$(cd "$TMP/repo" && PATH="$TMP/nothing:/usr/bin:/bin" bash "$PULSE" 2>&1)
contains "missing gh is explicit" "$out" "unavailable — gh (GitHub CLI) is not installed"

mkdir -p "$TMP/repo/plans/conversations" "$TMP/repo/plans/implementation"
printf '# a\n**Status:** open thing\n' > "$TMP/repo/plans/conversations/2026-01-02-a.md"
out=$(cd "$TMP/repo" && PATH="$PATHW" bash "$PULSE" 2>&1)
contains "finds notes nested in subfolders" "$out" "plans/conversations/2026-01-02-a.md"
contains "extracts the status marker line" "$out" "**Status:** open thing"

printf '# b\n**Status:** flat thing\n' > "$TMP/repo/plans/2026-01-03-b.md"
out=$(cd "$TMP/repo" && PATH="$PATHW" bash "$PULSE" 2>&1)
contains "still finds notes sitting flat" "$out" "plans/2026-01-03-b.md"

mkrepo "$TMP/bare" >/dev/null
out=$(cd "$TMP/bare" && PATH="$PATHW" bash "$PULSE" 2>&1)
rc=$?
check "repo with no plans dir exits 0" "0" "$rc"

mkdir -p "$TMP/nogit" && echo hi > "$TMP/nogit/a.txt"
out=$(cd "$TMP/nogit" && PATH="$PATHW" bash "$PULSE" 2>&1)
contains "no git falls back to a file listing" "$out" "### recently changed"

echo
echo "Record destination resolution"

RECORD="$REPO/commands/record/record.sh"

mkrepo "$TMP/w1" >/dev/null
mkdir -p "$TMP/w1/plans/conversations"
printf '# old\n' > "$TMP/w1/plans/conversations/2020-01-01-old.md"
out=$(cd "$TMP/w1" && bash "$RECORD" 2>&1)
contains "resolves a split notes dir (files two levels down)" "$out" "plans/conversations"
contains "reports an absolute target" "$out" "$TMP/w1/plans/conversations"
contains "warns when the target is not gitignored" "$out" "NOT IGNORED"
contains "shows house style from the newest record" "$out" "# old"

printf 'plans/\n' > "$TMP/w1/.gitignore"
out=$(cd "$TMP/w1" && bash "$RECORD" 2>&1)
contains "reports ignored once the rule exists" "$out" "ignored — safe"

mkrepo "$TMP/w2" >/dev/null
out=$(cd "$TMP/w2" && bash "$RECORD" 2>&1)
contains "proposes plans/ when no notes dir exists" "$out" "plans/conversations"
contains "says the directory would be created" "$out" "would be created"

mkrepo "$TMP/w3" >/dev/null
mkdir -p "$TMP/w3/plans" "$TMP/w3/docs"
printf '# a\n' > "$TMP/w3/plans/a.md"
printf '# b\n' > "$TMP/w3/docs/b.md"
out=$(cd "$TMP/w3" && bash "$RECORD" 2>&1)
contains "refuses to guess between two active dirs" "$out" "AMBIGUOUS"

mkrepo "$TMP/w4" >/dev/null
mkdir -p "$TMP/w4/plans/conversations"
today=$(date +%Y-%m-%d)
printf '# today\n' > "$TMP/w4/plans/conversations/$today-existing.md"
out=$(cd "$TMP/w4" && bash "$RECORD" 2>&1)
contains "lists an existing record for today" "$out" "$today-existing.md"
contains "advises updating rather than duplicating" "$out" "update it instead"

mkdir -p "$TMP/w5" && printf '# x\n' > "$TMP/w5/a.md"
out=$(cd "$TMP/w5" && bash "$RECORD" 2>&1); rc=$?
check "works outside a git repo" "0" "$rc"
contains "says there is nothing to ignore outside git" "$out" "not a git repo"

out=$(cd "$TMP/w1" && bash "$RECORD" 2>&1)
check "probe writes nothing (no new files)" \
  "1" \
  "$(ls -1 "$TMP/w1/plans/conversations" | wc -l | tr -d ' ')"

echo
echo "Nothing machine-specific ships"

# These commands run on other people's machines. A hardcoded home directory or
# an address baked into a published file is both a privacy leak and a bug.
leak=$(grep -rnE '/(Users|home)/[a-zA-Z0-9._-]+' "$REPO/commands" "$REPO/README.md" 2>/dev/null)
check "no absolute home paths in shipped files" "" "$leak"

mail=$(grep -rnE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$REPO/commands" "$REPO/README.md" 2>/dev/null)
check "no email addresses in shipped files" "" "$mail"

echo
echo "bash -n"
if bash -n "$PULSE"; then pass=$((pass + 1)); echo "  ok   pulse.sh parses"; else fail=$((fail + 1)); echo "  FAIL pulse.sh"; fi
if bash -n "$RECORD"; then pass=$((pass + 1)); echo "  ok   record.sh parses"; else fail=$((fail + 1)); echo "  FAIL record.sh"; fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
