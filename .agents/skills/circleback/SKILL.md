---
name: circleback
description: Use the Circleback CLI (`cb`/`circleback`) to search meetings, read notes/transcripts, and track action items from Rajit's AI meeting assistant. Use when the user asks about meeting notes, past conversations, action items, decisions, attendees, or follow-ups from their meetings.
---

# Circleback (CLI)

Circleback is Rajit's AI meeting assistant. It records, transcribes, and summarizes
meetings (Zoom, Google Meet, Teams, etc.) into structured notes, transcripts, and
action items. We use the **CLI** (not the MCP server) to access this data.

## Install

```bash
npm install -g @circleback/cli   # provides `circleback` and `cb`
cb login                         # opens browser for OAuth, stores token
```

## Commands

| Command | Description |
| --- | --- |
| `cb meetings [search]` | Find meetings by keyword, date range, tag, attendee, domain |
| `cb meetings read <ids...>` | Full detail: notes, attendees, action items, insights, tags, duration |
| `cb transcripts <search>` | Search transcripts; returns matches with timestamps |
| `cb transcripts read <ids...>` | Full transcript (speaker labels + timestamps) |
| `cb action-items [search]` | By keyword, status (pending/done), assignee, tag, date range |
| `cb calendar` | Search upcoming/past calendar events |
| `cb emails [search]` | Search connected email accounts |
| `cb people <names...>` | Look up people + interaction history |
| `cb companies <terms...>` | Look up companies by name/domain |
| `cb tags` | List workspace tags |
| `cb support [search]` | Circleback help docs |

All commands accept `--json` for structured output (pipe to `jq`).

## Examples

```bash
cb meetings "product review"          # search by keyword
cb meetings --last 7                  # last 7 days
cb meetings --from 2026-04-01 --to 2026-04-18
cb meetings read 12345                # numeric or linkId
cb action-items --json | jq '.[] | select(.status=="pending")'
cb transcripts "pricing discussion"
```

## Usage guidance

- Treat meeting content as confidential; don't exfiltrate notes.
- "What action items are open?" → `cb action-items` (filter pending).
- "What did we decide in X?" → `cb meetings` then `cb meetings read <id>`.
- Cite meeting name/date when quoting notes.
