---
description: Where this project is at — recent work, open PRs, decisions, next
allowed-tools: Bash(bash ~/.claude/commands/pulse.sh)
---

Project state (probe output below — do not read any files beyond this):

!`bash ~/.claude/commands/pulse.sh`

Using only the probe output above plus any project memory already in your context, give a terse status (≤8 lines):

- **In progress** — what's uncommitted or clearly mid-flight
- **Just shipped** — most recent merged/committed work
- **Open PRs** — count + one line each, or "none"
- **Blocked** — any open PR whose probe line shows CI failing, conflicts, or changes requested; name the PR and the reason. Say "nothing blocked" if all clean. Omit if there are no open PRs.
- **Next / open decisions** — prefer the `open items in recent notes` section, quoting the marker and citing its `file:line`; fall back to memory. Omit if nothing.

Don't read files beyond the probe output — the marker lines are the answer, not a pointer to go read the file. If nothing useful turns up, say so and suggest keeping a one-line log.
