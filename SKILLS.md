# Agent Skills

Skills used by openCode / agents, vendored under `.agents/skills/` and tracked
via `skills-lock.json` (reproducible install). Symlinked as `skills -> .agents/skills`.

## Tracked (actually used)

| Skill | Source | Notes |
|-------|--------|-------|
| `find-docs` | vendored | Library/framework docs lookup |
| `playwriter` | github `remorses/playwriter` | Browser automation via your Chrome |
| `circleback` | vendored | Meeting notes / follow-ups |

## Dropped (intentionally)

`gws-gmail`, `gws-drive` (not working yet), `yc-cli`, `remarkable-ssh-sync`,
`playwright-cli`. Restore from git history if needed.

## Install

```bash
npm install -g opencode-ai          # CLI
cd ~/dotfiles && ocx skills sync     # or: opencode skills sync
```

`bootstrap.sh --skills` does this for you.
