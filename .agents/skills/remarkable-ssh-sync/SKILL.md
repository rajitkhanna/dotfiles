---
name: remarkable-ssh-sync
description: Sync files from a reMarkable tablet over SSH into local folders. Use when the user asks to pull, mirror, back up, or sync reMarkable notes/files without running an MCP server.
---

# reMarkable SSH Sync

SSH-only file sync for reMarkable. No MCP runtime. No vision/OCR pipeline.

## Use this skill when

- User asks to pull or sync files from reMarkable
- User wants local backups/mirror of tablet documents
- User wants direct file workflows instead of MCP tools

## Source code reuse

This skill reuses existing transport logic from:

- `/Users/rajitkhanna/dotfiles/remarkable-mcp/remarkable_mcp/ssh.py`
- `/Users/rajitkhanna/dotfiles/remarkable-mcp/remarkable_mcp/api.py`

If the repo is not present locally, clone it first:

```bash
git clone https://github.com/SamMorrowDrums/remarkable-mcp.git /Users/rajitkhanna/dotfiles/remarkable-mcp
```

## Default sync target

- `/Users/rajitkhanna/Library/CloudStorage/Dropbox/notes/remarkable_sync`

## Command surface

Use the bundled script:

```bash
python3 /Users/rajitkhanna/dotfiles/.agents/skills/remarkable-ssh-sync/scripts/remarkable_sync.py status
python3 /Users/rajitkhanna/dotfiles/.agents/skills/remarkable-ssh-sync/scripts/remarkable_sync.py list
python3 /Users/rajitkhanna/dotfiles/.agents/skills/remarkable-ssh-sync/scripts/remarkable_sync.py pull --path "/Work/Meeting Notes"
python3 /Users/rajitkhanna/dotfiles/.agents/skills/remarkable-ssh-sync/scripts/remarkable_sync.py sync
```

## Behavior

- PDF/EPUB: saves raw file bytes
- Notebook/other docs: saves archive as `.rmdoc.zip` and extracts contents into a sibling folder
- Preserves path hierarchy from tablet
- Uses manifest for incremental sync:
  - `<dest>/.remarkable_manifest.json`

## SSH settings

Supports aliases from `~/.ssh/config` via `--host`.

Examples:

```bash
python3 /Users/rajitkhanna/dotfiles/.agents/skills/remarkable-ssh-sync/scripts/remarkable_sync.py status --host remarkable-usb
python3 /Users/rajitkhanna/dotfiles/.agents/skills/remarkable-ssh-sync/scripts/remarkable_sync.py sync --host remarkable
```

## Workflow

1. Run `status`
2. Run `list` to locate file paths
3. Run `pull --path "..."` for one file or `sync` for all changed docs
4. Confirm files in destination folder
