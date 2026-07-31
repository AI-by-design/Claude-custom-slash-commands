# `/wrap`

Saves the session as a dated record you can find again later.

```
/wrap
/wrap auth rewrite        # name the topic
```

Writes to `plans/conversations/YYYY-MM-DD-topic.md`: what was decided, what was rejected
and why, and what's still open. For the moment you want to close the window without
losing the thread.

## Install

```bash
cp commands/wrap/wrap* ~/.claude/commands/
```

Both files — `wrap.md` and `wrap.sh` — go in together and must sit beside each other.

## Requirements

- **bash** — built in on macOS and Linux
- **git** — optional; used to find the repo root and check whether records are ignored

No network access, no GitHub CLI.

## What it does

- **Finds the notes folder you already use** — `plans/`, `docs/`, `decisions/`, `notes/`,
  including one level of subfolders. If two are equally in use it asks rather than guessing.
- **Warns before writing** if that folder isn't gitignored. Session records usually
  aren't meant to be committed.
- **One record per session.** Run it again later and it updates the day's record instead
  of leaving you near-duplicates.
- **Follows your house style**, taken from your most recent record.
- **Verifies.** It reads the file back off disk and reports the absolute path and line
  count. "Saved" is a claim; the read-back is what makes it true.

## Run it at checkpoints

`/wrap` writes from what's in the context window. In a long session the earliest turns
have been compacted and the exact wording is gone — so a record written at the very end
is a faithful summary rather than a transcript.

It's told to say so when that's the case, rather than paraphrasing and passing it off as
quotation. Running it a few times as the work progresses keeps the detail.

## Boundaries

`wrap.sh` is read-only and creates nothing. The command writes exactly one file. It never
commits, never pushes, and never touches the network.

## Files

| File | Role |
|------|------|
| `wrap.md` | The command — what to write and where |
| `wrap.sh` | Read-only probe; resolves the destination and reports it |
