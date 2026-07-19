# Rajit's Dotfiles

One-command environment bootstrap for a new machine — CLI toolchain, agent
skills, fonts, and all configs (neovim, yazi, tmux, wezterm, sketchybar, yabai,
opencode, lazygit, gh, etc.).

Heavily modeled on [Josean Martinez's dev-environment-files](https://github.com/josean-dev/dev-environment-files)
— same structure and bootstrap approach. Go star his repo.

## Quick start

```bash
git clone https://github.com/rajitkhanna/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
exec zsh
```

`bootstrap.sh` detects OS (Ubuntu/Debian or macOS) and:

- installs the CLI toolchain (below)
- symlinks the tracked dotfiles
- installs/“vendors” the agent skills (see [SKILLS.md](SKILLS.md))

Targeted runs: `./bootstrap.sh --tools`, `--dotfiles`, `--skills`.

On **Linux**, `--dotfiles` replaces `~/.zshrc` with the captured snapshot (it
backs up the live file first). To avoid overwriting your current shell config,
pass `--safe` — it appends only the missing blocks (XDG path, p10k sources,
zoxide/eza aliases, fzf-git) to your existing `~/.zshrc`:

```bash
./bootstrap.sh --safe          # full install, but merge into ~/.zshrc
./bootstrap.sh --safe --dotfiles   # only merge the dotfiles blocks
```

## CLI software

Installed by `bootstrap.sh`:

| Tool | Purpose |
|------|---------|
| `bat` / `batcat` | better cat |
| `eza` | better ls (icons) |
| `fd` / `fdfind` | better find |
| `fzf` | fuzzy finder (+ `fzf-git.sh` bindings) |
| `ripgrep` (`rg`) | better grep |
| `git-delta` (`delta`) | git diff pager |
| `zoxide` (`z`) | better cd |
| `tmux` | terminal multiplexer |
| `lazygit` | git TUI (prebuilt via `gah`) |
| `yazi` | file manager (prebuilt via `gah`) |
| `neovim` | editor |
| `gh` | GitHub CLI |
| `jq` | JSON |
| `htop` / `btop` / `bottom` / `ncdu` | monitors |
| `rclone` | cloud sync |
| `atuin` / `starship` | shell history / prompt (macOS) |
| `zsh` + powerlevel10k + autosuggest + syntax-highlight | shell |
| `node` (LTS) + `npm` globals: `opencode-ai`, `ctx7`, `vercel`, `@circleback/cli` | JS tooling |
| `python3` + pip/venv, `cmake`, `ninja`, Rust (`cargo`) | build toolchains |
| `ffmpeg`, `tesseract-ocr`, `xclip`/`xsel` | media / clipboard |

Nerd Font (Meslo) + Noto Color Emoji installed automatically on Linux for p10k
icons.

## Layout

```
dotfiles/
├── bootstrap.sh          # the installer
├── SKILLS.md             # agent skill inventory
├── skills-lock.json      # reproducible skill installs
├── host/                 # droplet-specific configs (zshrc, tmux, p10k, fzf-git)
├── .config/              # all app configs (nvim, yazi, opencode, …)
├── .agents/skills/       # vendored agent skills
├── .zshrc .tmux.conf …   # macOS dotfiles (tracked, symlinked)
```

On **macOS** configs symlink from `~` into the repo. On **Linux/droplet**
`XDG_CONFIG_HOME` points at `dotfiles/.config` so every app resolves configs
from the repo directly.

## Agent skills

Only the skills I actually use are tracked (the rest are intentionally dropped):

| Skill | Source | Notes |
|-------|--------|-------|
| `find-docs` | vendored | Library/framework docs lookup |
| `playwriter` | github `remorses/playwriter` | Browser automation via your Chrome |
| `circleback` | vendored | Meeting notes / follow-ups (via `@circleback/cli`) |

See [SKILLS.md](SKILLS.md). Vendored under `.agents/skills/`, tracked by
`skills-lock.json`, symlinked as `skills`.

> gws-gmail/gws-drive, yc-cli, remarkable-ssh-sync, playwright-cli were removed
> (not working / not needed). Re-add from `skills-lock.json` history if wanted.

## Credits

- [Josean Martinez — dev-environment-files](https://github.com/josean-dev/dev-environment-files)
  — the structure and bootstrap approach this repo is built on. Go star it.
- [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [marverix/gah](https://github.com/marverix/gah) — prebuilt binary installer.
