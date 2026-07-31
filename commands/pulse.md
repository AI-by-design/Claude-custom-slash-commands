---
description: Where this project is at — recent work, open PRs, decisions, next
allowed-tools: Bash(bash ~/.claude/commands/pulse.sh)
---

Project state (probe output below — do not read any files beyond this):

!`bash ~/.claude/commands/pulse.sh`

Using only the probe output above plus any project memory already in your context, give a terse status (≤8 lines):

- **In progress** — what's uncommitted or clearly mid-flight
- **Just shipped** — most recent merged/committed work
- **Open PRs** — use the `count:` line, then one line each. `count: 0` means none. `count: 50+` means the list is truncated — say so.
- **Blocked** — any open PR whose line shows CI failing, CI needs attention, conflicts, or changes requested; name the PR and the reason. Say "nothing blocked" only when every open PR is clear. Omit if there are no open PRs.
- **Next / open decisions** — prefer the `open items in recent notes` section, quoting the marker and citing its `file:line`; fall back to memory. Omit if nothing.

If a section reads `unavailable — <reason>`, report it as unavailable and give the reason. Never turn it into "none" or "nothing blocked" — a probe that could not check is not the same as nothing to find. The same goes for `no checks reported`, which means no CI ran, not that CI passed; and `mergeability pending`, which means GitHub is still computing.

Don't read files beyond the probe output — the marker lines are the answer, not a pointer to go read the file. If nothing useful turns up, say so and suggest keeping a one-line log.
