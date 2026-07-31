# Claude slash commands

A small collection of [Claude Code](https://claude.com/claude-code) slash commands.
First up: **`/pulse`** — a token-frugal "where is this project at?" status command.

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

## Install

```bash
git clone https://github.com/AI-by-design/Claude-custom-slash-commands.git
cp Claude-custom-slash-commands/commands/pulse.* ~/.claude/commands/
```

Then type `/pulse` in any project. That's it.

> Prefer not to clone? Download `commands/pulse.md`, `commands/pulse.sh` and
> `commands/pulse-pr.jq`, and drop all three into `~/.claude/commands/`.
> `pulse-pr.jq` must sit beside `pulse.sh` — without it you still get your PRs,
> just without the CI and review state.

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

28 checks, no network and no GitHub auth required — `gh` is stubbed. Covers PR state
rendering (green, failing, in progress, action-required, stale, conflicts, unknown
mergeability, draft, legacy check shapes, current-branch ordering) and probe behaviour
(repo root, subdirectory, linked worktree, missing `gh`, failing `gh`, nested and flat
notes, no plans dir, no git at all).

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

- **Read-only.** It only runs `git` / `gh` / `ls` / `head` / `grep` / `cut` / `jq` read
  commands — never writes, deletes, or pushes. No user input is interpolated into any
  command.
- **First run** shows a one-time permission prompt — approve it once.
- **Read `pulse.sh` before installing.** It auto-runs when you type `/pulse`, so
  treat it like any script you'd add to your shell.
- **Don't run `/pulse` in a repo you don't trust** — it runs `git` in the current
  folder, and a malicious `.git/config` can abuse that. This is a general git
  caution, not specific to this command.

## License

[MIT](./LICENSE)
