# Agent Skills

Skills used by openCode / agents, vendored under `.agents/skills/` and tracked
via `skills-lock.json` (reproducible install). Symlinked as `skills -> .agents/skills`.

## Typically used

| Skill | Source | Notes |
|-------|--------|-------|
| `gws-gmail` | github `googleworkspace/cli` | Gmail send/read |
| `gws-drive` | github `googleworkspace/cli` | Google Drive |
| `playwriter` | github `remorses/playwriter` | Browser automation via your Chrome |
| `find-docs` | vendored | Library/framework docs lookup |
| `company-research` | vendored | Exa company research |
| `exa-lead-gen` | vendored | Lead list generation |
| `people-research` | vendored | Exa people research |
| `yc-cli` | vendored | YC Bookface CLI |
| `remarkable-ssh-sync` | vendored | reMarkable tablet sync |
| `playwright-cli` | vendored | Playwright MCP QA |

## Install

```bash
npm install -g opencode-ai          # CLI
cd ~/dotfiles && ocx skills sync     # or: opencode skills sync
```

`bootstrap.sh --skills` does this for you.
