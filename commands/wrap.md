---
description: Save this session as a dated record you can find again later
allowed-tools: Bash(bash ~/.claude/commands/wrap.sh), Read, Write, Edit, Bash(mkdir:*), Bash(ls:*), Bash(wc:*), Bash(git check-ignore:*)
---

Destination probe:

!`bash ~/.claude/commands/wrap.sh`

Write a record of this conversation so it survives the window being closed.

## Where

Use the `resolved` path from the probe. Create the directory if it doesn't exist.

- If the probe says **AMBIGUOUS**, stop and ask which directory to use. Don't guess.
- If it says **NOT IGNORED**, say so and offer to add the ignore rule before writing. A session record usually isn't meant to be committed.
- If `$ARGUMENTS` is present, treat it as the topic.

## Filename

`<date from probe>-<kebab-slug>.md`, slug from the topic — `2026-01-04-auth-rewrite-decisions.md`.

If the probe lists an existing record for today covering this same session, **update that file** instead of creating a second one. `/wrap` is expected to run several times in a session; each run should leave one record, not a pile of near-duplicates.

## What to write

Match the house style if the probe showed one. Otherwise:

```markdown
# <Title>

**Date:** <date>
**Status:** <where this stands — decided / in progress / parked>
**Purpose:** <what this record is for, in one or two lines>

## Source material
<links, files touched, screenshots, PRs — anything a reader would need>

---

<body>
```

The body is a **thematic synthesis**, not a transcript:

- Group by thread, not by turn. One section per topic that actually went somewhere.
- **Quote decisions verbatim.** The exact words matter most and are the first thing lost.
- Record what was rejected and why — that's what stops the same ground being re-covered next week.
- Mark what's still open, in its own section, so the next session can pick it up.
- Note what was built, what was only discussed, and what was left untouched.

Two rules on accuracy:

- **Don't invent.** If a detail isn't in the conversation, leave it out. A record that reads well but misremembers is worse than a short one.
- **Say what you can't recover.** In a long session the early turns have been compacted and the exact wording is gone. Write what survives and note the gap — don't paraphrase and present it as quotation. If this matters, say so plainly at the end, and suggest running `/wrap` at checkpoints rather than only at the end.

## Then verify

Never report a path you haven't checked. After writing:

1. Read the file back off disk.
2. Confirm it's non-empty and contains what you just wrote.
3. Report the **absolute path** and the line count.

If anything failed — directory missing, write refused, empty file — say so plainly. "Saved" is a claim; the read-back is what makes it true. A record you believe exists and can't find later is worse than knowing it was never written.
