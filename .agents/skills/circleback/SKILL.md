---
name: circleback
description: Use Circleback (AI meeting assistant) via its remote MCP server to search meetings, read notes/transcripts, and track action items. Use when the user asks about meeting notes, past conversations, action items, decisions, attendees, or follow-ups from their meetings.
---

# Circleback

Circleback is Rajit's AI meeting assistant. It records, transcribes, and summarizes
meetings (Zoom, Google Meet, Teams, etc.) into structured notes, transcripts, and
action items. Data is accessed exclusively through Circleback's **remote MCP server**
— there is no traditional REST API.

## Connection

Remote MCP endpoint (Streamable HTTP, OAuth):

```
https://app.circleback.ai/api/mcp
```

### Connect in openCode

Add to `~/.config/opencode/opencode.json` under `mcp` / `servers`:

```json
{
  "mcp": {
    "servers": {
      "circleback": {
        "type": "http",
        "url": "https://app.circleback.ai/api/mcp"
      }
    }
  }
}
```

On first use the client opens a browser for OAuth login, then reuses the token.

### Connect in other clients

- Codex: `codex mcp add circleback --url https://circleback.ai/api/mcp`
- Claude Code: `claude mcp add circleback --transport http https://app.circleback.ai/api/mcp`
- Cursor / VS Code: add the same URL as an HTTP MCP server.

## Tools available (via MCP)

- `SearchMeetings` — find meetings by keyword, date range, tags, attendee, domain
- `ReadMeetings` — full meeting detail: notes, attendees, action items, insights, tags, duration
- `SearchTranscripts` — search across transcripts, returns matches with timestamps
- `GetTranscriptsForMeetings` — full transcript (speaker labels + timestamps)
- `SearchActionItems` — by keyword, status (pending/done), assignee, tag, date range
- `SearchCalendarEvents` — past/upcoming calendar events
- `SearchEmails` — connected email threads
- `FindProfiles` / `FindCompanies` — people & company interaction history
- `ListTags` — workspace tags for filtering
- `SearchSupportArticles` — Circleback help docs

## Usage guidance

- Treat meeting content as confidential; don't exfiltrate notes.
- For "what action items are open?" → `SearchActionItems` (status=pending).
- For "what did we decide in the X meeting?" → `SearchMeetings` then `ReadMeetings`.
- Cite the meeting name/date when quoting notes.
