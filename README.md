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
| `gws-sheets` / `gws-sheets-read` / `gws-sheets-append` | github `googleworkspace/cli` | Google Sheets read/write |
| `gws-docs` / `gws-docs-write` | github `googleworkspace/cli` | Google Docs read/write |
| `gws-gmail` (+ send/read/reply/forward/triage/watch) | github `googleworkspace/cli` | Gmail via `gws` CLI |
| `gws-drive` / `gws-drive-upload` | github `googleworkspace/cli` | Google Drive files/folders |

See [SKILLS.md](SKILLS.md). Vendored under `.agents/skills/`, tracked by
`skills-lock.json`, symlinked as `skills`.

> gws-drive (Drive) was left out — add from `googleworkspace/cli` if you need it.
> yc-cli, remarkable-ssh-sync, playwright-cli were removed (not needed).

## Google Workspace (`gws`)

`gws` is the Google Workspace CLI that powers the `gws-*` skills (Gmail, Drive,
Sheets, Docs, Calendar, …). `bootstrap.sh` installs it automatically
(`npm i -g @googleworkspace/cli`, or `brew install googleworkspace-cli` on macOS).
Verify:

```bash
command -v gws && gws --version
```

### Authenticate

`gws` uses Google OAuth2. The interactive browser flow runs **once**; after
that a long-lived **refresh token** keeps it working with no browser.

**Interactive (Mac / desktop):**
```bash
gws auth login          # opens browser, completes Google OAuth
gws auth setup          # (optional) create/configure the GCP project + credentials
gws gmail users getProfile --params '{"userId":"me"}'   # verify
```

**Headless / SSH server (e.g. the hermes droplet) — no browser needed:**
Export the reusable credential from a machine that's already authed, then copy
it over. `gws auth export --unmasked` prints a standard `authorized_user` JSON
(`client_id` + `client_secret` + `refresh_token`) — the refresh token is
long-lived.

```bash
# 1) on your Mac (already authed):
gws auth export --unmasked > ~/gws-creds.json

# 2) copy to the server:
scp ~/gws-creds.json root@hermes:/root/.config/gws/credentials.json

# 3) on the server:
gws auth status         # shows has_refresh_token: true, no browser required
```

> Security: `gws-creds.json` is a live credential — never commit it to the repo
> or paste it into chat. It lives only in `~/.config/gws/credentials.json` on
> each machine. `gws auth logout` revokes it.

### Skills

The `gws-*` skills are vendored under `.agents/skills/` and tracked in
`skills-lock.json` (source `googleworkspace/cli`). They expect `gws` on `$PATH`
and read `gws-shared/SKILL.md` for auth + global flags.

## Credits

- [Josean Martinez — dev-environment-files](https://github.com/josean-dev/dev-environment-files)
  — the structure and bootstrap approach this repo is built on. Go star it.
- [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [marverix/gah](https://github.com/marverix/gah) — prebuilt binary installer.
