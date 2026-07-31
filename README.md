# Claude slash commands

Small, focused slash commands for [Claude Code](https://claude.com/claude-code).

| Command | What it gives you | Docs |
|---------|-------------------|------|
| `/pulse` | Where this project is at — in progress, just shipped, open PRs, what's blocked, what's next | [commands/pulse](./commands/pulse) |
| `/record` | The session saved as a dated record you can find again later | [commands/record](./commands/record) |

Each command is a prompt file plus a read-only probe script. The probe gathers state,
Claude writes the answer. No crawling the repo, no reading whole files.

## Install

Everything:

```bash
git clone https://github.com/AI-by-design/Claude-custom-slash-commands.git
cd Claude-custom-slash-commands
find commands -type f ! -name 'README.md' -exec cp {} ~/.claude/commands/ \;
```

Or one command at a time — see its folder above. Files install flat into
`~/.claude/commands/`; each `.sh` must sit beside its `.md`.

First run shows a one-time permission prompt. Approve it once.

## Requirements

- **bash** — built in on macOS and Linux
- **git** — optional
- **gh** ([GitHub CLI](https://cli.github.com), authenticated) — optional, `/pulse` only
- **jq** — optional, `/pulse` only

Each command's README lists what it actually needs and how it degrades without it.

## Tests

```bash
bash tests/run.sh
```

44 checks. No network and no GitHub auth required — `gh` is stubbed.

Covers PR state rendering, probe behaviour across repo roots, subdirectories and
worktrees, missing and failing `gh`, `/record` destination resolution, and a guard that no
absolute home path or email address ships in a published file.

## Security

- **The probe scripts are read-only.** They run only `git`, `gh`, `ls`, `head`, `grep`,
  `cut` and `jq` read commands. No user input is interpolated into any command.
- **`/record` writes one file** — a markdown record in your notes folder, after the probe.
  It never commits and never pushes, and it warns you if that folder isn't gitignored.
- **Nothing leaves your machine.** `/pulse` reads GitHub through your own authenticated
  `gh`; `/record` doesn't touch the network.
- **Read the `.sh` before installing.** It auto-runs when you type the command, so treat
  it like any script you'd add to your shell.
- **Don't run these in a repo you don't trust.** They run `git` in the current folder,
  and a malicious `.git/config` can abuse that — a general git caution, not specific to
  these commands.

## Adding a command

One folder per command, same shape every time:

```
commands/<name>/
├── README.md      what it gives you, install, requirements, limits
├── <name>.md      the prompt — frontmatter, one inline ! step, what to do with the output
└── <name>.sh      read-only probe — prints ### section blocks, exits 0 even when things are missing
```

Then add tests to `tests/run.sh` including the failure paths, and a row in the table above.

Two conventions worth keeping: probes report `unavailable — <reason>` rather than going
silent, and prompts are told never to read that as "nothing found".

## License

[MIT](./LICENSE)
