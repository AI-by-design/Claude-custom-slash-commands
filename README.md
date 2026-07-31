# Claude slash commands

A small collection of [Claude Code](https://claude.com/claude-code) slash commands.

- **`/pulse`** — a token-frugal "where is this project at?" status command.
- **`/wrap`** — save the session as a dated record you can find again later.

## `/pulse`

Type `/pulse` in any project and get a terse status:

- **In progress** — uncommitted / mid-flight work
- **Just shipped** — most recent commits
- **Open PRs** — via the GitHub CLI, each with its CI, review and merge state
- **Blocked** — which PR is stuck and why (failing check, conflicts, changes requested)
- **Next / open decisions** — the actual open lines from recent notes
  (`plans/`, `DECISIONS.md`, …), quoted with `file:line`

It's built to be cheap: a single read-only probe script runs first, and Claude just
summarizes the output — no crawling the repo, no reading whole files.

## `/wrap`

Type `/wrap` — optionally `/wrap auth rewrite` to name the topic — and the session
gets written to `plans/conversations/YYYY-MM-DD-topic.md`: what was decided, what was
rejected and why, and what's still open.

It's for the moment you want to close the window without losing the thread. Run it at
checkpoints, not just at the end — see the caveat below.

- **Finds the right folder.** Whatever you already use — `plans/`, `docs/`, `notes/` —
  picked by which one actually holds notes, counted two levels deep so a folder split
  into subfolders still counts. If two are equally in use it asks instead of guessing.
- **Won't quietly make records committable.** If the target isn't gitignored it says so
  and offers the rule first.
- **One record per session.** Run it again later and it updates today's record rather
  than leaving you a pile of near-duplicates.
- **Matches your house style.** It reads how your most recent record opens and follows it.
- **Verifies.** It reads the file back off disk and reports the absolute path and line
  count. "Saved" is a claim; the read-back is what makes it true.

**One honest limit.** It writes from what's in the context window. In a long session the
early turns have been compacted and the exact wording is gone — so a record written at
the very end is a faithful summary, not a transcript. It's told to say so rather than
paraphrase and pass it off as quotation. Run `/wrap` at natural checkpoints and you keep
the detail.

## Install

```bash
git clone https://github.com/AI-by-design/Claude-custom-slash-commands.git
cp Claude-custom-slash-commands/commands/* ~/.claude/commands/
```

Then type `/pulse` or `/wrap` in any project. That's it.

> Prefer not to clone? Download the files for the command you want and drop them
> into `~/.claude/commands/` — `pulse.md`, `pulse.sh` and `pulse-pr.jq` for
> `/pulse`; `wrap.md` and `wrap.sh` for `/wrap`. Each `.sh` needs to sit beside
> its `.md`. Without `pulse-pr.jq` you still get your PRs, just without the CI
> and review state.

## Requirements

- **bash** — built in on macOS/Linux
- **git** — optional; enables branch / uncommitted / recent-commit status
- **gh** (GitHub CLI, authenticated) — optional; enables open + merged PRs
- **jq** — optional; enables the CI / review / conflict state on open PRs

Without git/gh, `/pulse` falls back to listing recently changed files. Without jq, open
PRs still show up — just as a plain list, without the blocked state.

Nothing fails silently: if `gh` is missing, unauthenticated, or offline, the section
reads `unavailable — <reason>` rather than going blank. A blank section would be
indistinguishable from "no open PRs", which is a worse answer than no answer.

## Tests

```bash
bash tests/run.sh
```

44 checks, no network and no GitHub auth required — `gh` is stubbed.

Covers PR state rendering (green, failing, in progress, action-required, stale,
conflicts, unknown mergeability, draft, legacy check shapes, current-branch ordering);
probe behaviour (repo root, subdirectory, linked worktree, missing `gh`, failing `gh`,
nested and flat notes, no plans dir, no git at all); `/wrap` destination resolution
(split folder, none, ambiguous, ignored vs not, existing same-day record, outside git,
and that the probe writes nothing); and that no absolute home path or email address
ever ships in a published file.

## How it works

`pulse.md` is the command. Its one inline step runs `pulse.sh`, a read-only probe
script that gathers git state, open/merged PRs with their check and review state, and
the open lines from recent decision notes. Claude reads that output and writes the
summary. All the shell logic lives in `pulse.sh` so the command stays simple and
predictable, and the PR-rendering rules live in `pulse-pr.jq` so they can be tested
on their own.

Repo detection uses `git rev-parse --is-inside-work-tree`, so `/pulse` works from a
subdirectory and inside a linked worktree — not only at the repo root.

Notes are never read whole. The probe greps them for status markers — `**Status:**`,
`**Open decision:**`, unchecked `- [ ]` boxes, and status/next headings — and passes
through at most four matching lines per file, from the three most recently touched
files. That keeps the answer in the probe output instead of sending Claude off to read
a 20KB planning doc.

## Security

- **Both probe scripts are read-only.** `pulse.sh` and `wrap.sh` only run
  `git` / `gh` / `ls` / `head` / `grep` / `cut` / `jq` read commands — they never write,
  delete, or push. No user input is interpolated into any command.
- **`/wrap` writes one file**, and only after the probe. It creates or updates a single
  markdown record in your notes folder. It never commits and never pushes — and it warns
  you first if that folder isn't gitignored.
- **Nothing leaves your machine.** Neither command uploads anything. `/pulse` reads from
  GitHub through your own authenticated `gh`; `/wrap` doesn't touch the network at all.
- **First run** shows a one-time permission prompt — approve it once.
- **Read the `.sh` before installing.** It auto-runs when you type the command, so treat
  it like any script you'd add to your shell.
- **Don't run these in a repo you don't trust** — they run `git` in the current folder,
  and a malicious `.git/config` can abuse that. This is a general git caution, not
  specific to these commands.

## License

[MIT](./LICENSE)
