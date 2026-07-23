---
name: yc-cli
description: |
  YC CLI helper — knows the available commands, usage patterns, and how to help
  users interact with Bookface from their terminal. Use when the user asks about
  the YC CLI, wants to search Bookface, ask the YC agent a question, or manage
  their YC CLI authentication.
allowed-tools:
  - Bash
---

# YC CLI

The YC CLI (`yc`) lets YC community members interact with Bookface from their terminal.

## Usage

Before giving exact command syntax, check the CLI help so this skill does not
drift from the installed version:

```bash
yc --help
yc <command> --help
```

Use `yc skills --help` for skill installation commands.

## Capabilities

- Authenticate, log out, and show the current user.
- Search Bookface and return formatted or JSON results.
- Ask the YC agent a question from the terminal.
- Upload founder files and download YC content.
- Install this bundled skill or YC-maintained skills.
- Update the local CLI.

## Notes

- Credentials are stored at `~/.yc/credentials.json` and refresh automatically.
- Download continue state is stored in the output directory at `.yc/download.json`.
- `yc files download` only creates or overwrites files; it does not delete files
  that are no longer downloadable.
- If the user sees "Not logged in", tell them to run `yc login`.
- The CLI may be installed as `ycp` if an existing `yc` command was detected.
- The `agent` command streams its response to stdout in real time.
- The `files upload` command is intended for YC founders.
- The bundled `yc-cli` skill can be installed without founder-only API access.
- Other `skills` commands are intended for active YC users with access.
