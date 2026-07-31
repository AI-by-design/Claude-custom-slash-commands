# `/pulse`

Where this project is at, in about six lines.

```
/pulse
```

- **In progress** — uncommitted or mid-flight work
- **Just shipped** — most recent commits and merged PRs
- **Open PRs** — each with its CI, review and merge state
- **Blocked** — which PR is stuck, and why
- **Next / open decisions** — the actual open lines from your recent notes, quoted with `file:line`

## Install

```bash
cp commands/pulse/pulse* ~/.claude/commands/
```

All three files — `pulse.md`, `pulse.sh`, `pulse-pr.jq` — go in together and must sit
beside each other. Without `pulse-pr.jq` you still get your PRs, just without their state.

## Requirements

- **bash** — built in on macOS and Linux
- **git** — optional; enables branch, uncommitted and recent-commit state
- **gh** ([GitHub CLI](https://cli.github.com), authenticated) — optional; enables PRs
- **jq** — optional; enables CI, review and conflict state

Without git or gh it falls back to listing recently changed files.

## What it reads

Works from any directory in the repo, including linked worktrees.

**Notes:** `plans/`, `docs/`, `decisions/`, `notes/` — including one level of subfolders,
so a folder split into `conversations/` and `implementation/` still counts — plus
`DECISIONS.md`, `CHANGELOG.md`, `NOTES.md`, `ROADMAP.md`.

Files are never read whole. It looks for `**Status:**`, `**Open decision:**`, unchecked
`- [ ]` boxes and status headings, and passes through a few matching lines per file.

**PRs:** the 50 most recent open ones. If there are more, it says so. The PR for your
checked-out branch is listed first.

## When something can't be checked

If `gh` is missing, unauthenticated, or offline, the section reads
`unavailable — <reason>`. It never turns a failed check into "none" — a probe that
couldn't look is not the same as nothing to find.

The same applies to check state: `no checks reported` means nothing ran, which is not
the same as passing.

## Files

| File | Role |
|------|------|
| `pulse.md` | The command — what to do with the probe output |
| `pulse.sh` | Read-only probe; gathers git, PR and notes state |
| `pulse-pr.jq` | Turns GitHub's PR JSON into one readable line each |
