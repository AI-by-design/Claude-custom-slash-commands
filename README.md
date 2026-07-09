# Claude slash commands

A small collection of [Claude Code](https://claude.com/claude-code) slash commands.
First up: **`/pulse`** — a token-frugal "where is this project at?" status command.

## `/pulse`

Type `/pulse` in any project and get a terse status:

- **In progress** — uncommitted / mid-flight work
- **Just shipped** — most recent commits
- **Open PRs** — via the GitHub CLI
- **Next / open decisions** — pulled from recent notes (`plans/`, `DECISIONS.md`, …)

It's built to be cheap: a single read-only probe script runs first, and Claude just
summarizes the output — no crawling the repo, no reading whole files.

## Install

```bash
git clone https://github.com/AI-by-design/Claude-custom-slash-commands.git
cp Claude-custom-slash-commands/commands/pulse.md Claude-custom-slash-commands/commands/pulse.sh ~/.claude/commands/
```

Then type `/pulse` in any project. That's it.

> Prefer not to clone? Download `commands/pulse.md` and `commands/pulse.sh` and drop
> both into `~/.claude/commands/`.

## Requirements

- **bash** — built in on macOS/Linux
- **git** — optional; enables branch / uncommitted / recent-commit status
- **gh** (GitHub CLI, authenticated) — optional; enables open + merged PRs

Without git/gh, `/pulse` falls back to listing recently changed files.

## How it works

`pulse.md` is the command. Its one inline step runs `pulse.sh`, a read-only probe
script that gathers git state, open/merged PRs, and the names of recent decision
notes. Claude reads that output and writes the summary. All the shell logic lives in
`pulse.sh` so the command stays simple and predictable.

## Security

- **Read-only.** It only runs `git` / `gh` / `ls` / `head` read commands — never
  writes, deletes, or pushes. No user input is interpolated into any command.
- **First run** shows a one-time permission prompt — approve it once.
- **Read `pulse.sh` before installing.** It auto-runs when you type `/pulse`, so
  treat it like any script you'd add to your shell.
- **Don't run `/pulse` in a repo you don't trust** — it runs `git` in the current
  folder, and a malicious `.git/config` can abuse that. This is a general git
  caution, not specific to this command.

## License

[MIT](./LICENSE)
