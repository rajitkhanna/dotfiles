#!/usr/bin/env bash
#
# bootstrap.sh — spin up a new machine with Rajit's full environment.
#
# Installs the CLI toolchain, agent skills, fonts, and symlinks the dotfiles
# tracked in this repo. Works on Ubuntu/Debian (incl. the hermes droplet) and
# macOS (Homebrew).
#
# Usage:
#   ./bootstrap.sh            # full install (detect OS)
#   ./bootstrap.sh --tools    # only CLI tools
#   ./bootstrap.sh --dotfiles # only symlink configs
#   ./bootstrap.sh --skills   # only agent skills
#   ./bootstrap.sh --safe     # merge config into existing ~/.zshrc (no overwrite)
#
# On Linux, --dotfiles replaces ~/.zshrc with the captured snapshot (after
# backing it up). Pass --safe to instead append only the missing blocks, so
# your live ~/.zshrc is never overwritten.
#
# Safe to re-run. Idempotent where possible.

set -euo pipefail

# Resolve repo root (where this script lives).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_FILES="$REPO_ROOT/host"

# ---- colors ----------------------------------------------------------------
if [[ -t 1 ]]; then
  c_b="\033[0;34m"; c_g="\033[0;32m"; c_y="\033[0;33m"; c_r="\033[0;31m"; c_n="\033[0m"
else
  c_b=""; c_g=""; c_y=""; c_r=""; c_n=""
fi
log()   { echo -e "${c_b}==>${c_n} $*"; }
ok()    { echo -e "${c_g}ok:${c_n} $*"; }
warn()  { echo -e "${c_y}warn:${c_n} $*"; }
err()   { echo -e "${c_r}err:${c_n} $*"; }

# ---- flags ------------------------------------------------------------------
DO_TOOLS=1; DO_DOTFILES=1; DO_SKILLS=1
for a in "$@"; do
  case "$a" in
    --tools)    DO_DOTFILES=0; DO_SKILLS=0 ;;
    --dotfiles) DO_TOOLS=0; DO_SKILLS=0 ;;
    --skills)   DO_TOOLS=0; DO_DOTFILES=0 ;;
    --safe)     SAFE_MERGE=1 ;;
    -h|--help)  sed -n '3,20p' "$0"; exit 0 ;;
    *) warn "unknown arg: $a" ;;
  esac
done

# SAFE_MERGE: append only missing config blocks to the EXISTING ~/.zshrc
# instead of replacing it with the captured snapshot. Off by default.
SAFE_MERGE="${SAFE_MERGE:-0}"

OS="$(uname -s)"
case "$OS" in
  Linux*)  OS_FAMILY=linux ;;
  Darwin*) OS_FAMILY=macos ;;
  *) err "unsupported OS: $OS"; exit 1 ;;
esac
ok "detected $OS_FAMILY"

# =============================================================================
# 1. CLI TOOLCHAIN
# =============================================================================
if [[ "$DO_TOOLS" -eq 1 ]]; then
  log "installing CLI toolchain"

  if [[ "$OS_FAMILY" == "macos" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      log "installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
    brew update
    # Core utils + TUI
    brew install \
      bat eza fd fzf ripgrep git-delta zoxide tmux lazygit yazi neovim \
      gh jq htop ncdu btop bottom atuin starship rclone cmake ninja \
      zsh lua luajit node python pipx tesseract ffmpeg xclip xsel \
      pkg-config libssl-dev
    # powerlevel10k + zsh plugins
    brew install powerlevel10k
    brew install zsh-autosuggestions zsh-syntax-highlighting

  else
    # ---- Ubuntu / Debian ----
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
      build-essential cmake ninja-build pkg-config libssl-dev libfontconfig1-dev \
      neovim tmux zsh git gh curl wget unzip xclip xsel ffmpeg tesseract-ocr \
      ripgrep batcat fd-find fzf eza git-delta zoxide jq htop ncdu \
      python3 python3-pip python3-venv rclone lua5.1 luajit \
      ca-certificates gnupg2 fonts-noto-color-emoji apt-transport-https

    # Ubuntu renames bat/fd — normalize binary names.
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
    mkdir -p "$HOME/.local/bin"
    ln -sf /usr/lib/cargo/bin/fd "$HOME/.local/bin/fd" 2>/dev/null || \
      sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd

    # Node (LTS) via NodeSource.
    if ! command -v node >/dev/null 2>&1; then
      log "installing Node 22"
      curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
      sudo apt-get install -y nodejs
    fi

    # Rust toolchain (cargo/rustup) — needed for some tools & builds.
    if ! command -v cargo >/dev/null 2>&1; then
      log "installing Rust"
      curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
      . "$HOME/.cargo/env"
    fi

    # powerlevel10k (clone, no brew on Linux).
    if [[ ! -d "$HOME/powerlevel10k" ]]; then
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
    fi
    # zsh plugins.
    mkdir -p "$HOME/.zsh"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.zsh/zsh-autosuggestions" 2>/dev/null || true
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting" 2>/dev/null || true

    # gah — GitHub Releases App Installer (prebuilt lazygit/yazi).
    if ! command -v gah >/dev/null 2>&1; then
      log "installing gah"
      curl -fsSL https://raw.githubusercontent.com/marverix/gah/main/gah.sh -o /tmp/gah.sh
      sudo bash /tmp/gah.sh install gah
    fi
    # Prebuilt binaries for tools without good apt packages.
    command -v lazygit >/dev/null 2>&1 || sudo gah install lazygit
    command -v yazi    >/dev/null 2>&1 || sudo gah install yazi

    # Nerd Font (Meslo) for p10k icons.
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    if ! fc-list 2>/dev/null | grep -qi "MesloLGLDZ Nerd"; then
      log "installing Meslo Nerd Font"
      for v in Bold Regular BoldItalic Italic; do
        curl -fsSL "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGLDZ%20Nerd%20Font%20$v.ttf" \
          -o "$FONT_DIR/MesloLGLDZNerdFont$v.ttf"
      done
      fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
    fi
  fi

  # npm globals (openCode CLI, ctx7 docs, vercel, circleback CLI).
  if command -v npm >/dev/null 2>&1; then
    log "installing npm globals"
    npm install -g opencode-ai ctx7 vercel @circleback/cli 2>/dev/null || warn "npm global install failed (network?)"
  fi

  # fzf-git.sh key bindings.
  if [[ ! -d "$HOME/fzf-git.sh" ]]; then
    git clone --depth=1 https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh"
  fi

  ok "toolchain done"
fi

# =============================================================================
# 2. SYMLINK DOTFILES
# =============================================================================
if [[ "$DO_DOTFILES" -eq 1 ]]; then
  log "linking dotfiles"

  link() { # src dest
    local src="$1" dest="$2"
    if [[ -z "$src" || ! -e "$src" ]]; then warn "skip missing: $src"; return; fi
    if [[ -L "$dest" ]]; then rm -f "$dest"; fi
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      warn "exists (not link), backing up: $dest"; mv "$dest" "$dest.bak.$(date +%s)"
    fi
    ln -sf "$src" "$dest"; ok "link $dest -> $src"
  }

  # macOS repo layout: configs live in .config/ and are symlinked from ~.
  if [[ "$OS_FAMILY" == "macos" ]]; then
    link "$REPO_ROOT/.zshrc"          "$HOME/.zshrc"
    link "$REPO_ROOT/.tmux.conf"      "$HOME/.tmux.conf"
    link "$REPO_ROOT/.wezterm.lua"    "$HOME/.wezterm.lua"
    for d in nvim yazi sketchybar yabai skhd opencode lazygit gh ngrok; do
      link "$REPO_ROOT/.config/$d" "$HOME/.config/$d"
    done
    link "$REPO_ROOT/AGENTS.md" "$HOME/AGENTS.md"
    # opencode skills symlink (skills -> .agents/skills)
    link "$REPO_ROOT/.agents" "$HOME/.agents"
  else
    # Linux/droplet layout: XDG_CONFIG_HOME points at repo .config.
    link "$REPO_ROOT/host/tmux.conf.droplet" "$HOME/.tmux.conf"
    link "$REPO_ROOT/host/p10k.zsh.droplet" "$HOME/.p10k.zsh"
    link "$REPO_ROOT/host/fzf-git.sh" "$HOME/fzf-git.sh/fzf-git.sh"
    link "$REPO_ROOT/host/opencode-AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

    if [[ "$SAFE_MERGE" -eq 1 ]]; then
      # Don't replace the live ~/.zshrc. Append only the blocks that are
      # missing, so the existing config is preserved.
      log "safe-merge: appending missing blocks to existing ~/.zshrc"
      ZRC="$HOME/.zshrc"
      grep -q "XDG_CONFIG_HOME" "$ZRC" || \
        echo "export XDG_CONFIG_HOME=\"$REPO_ROOT/.config\"" >> "$ZRC"
      grep -q "fzf-git.sh" "$ZRC" || \
        echo "source $HOME/fzf-git.sh/fzf-git.sh" >> "$ZRC"
      grep -q "powerlevel10k.zsh-theme" "$ZRC" || \
        echo "source ~/powerlevel10k/powerlevel10k.zsh-theme" >> "$ZRC"
      grep -q "zsh-autosuggestions.zsh" "$ZRC" || \
        echo "source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" >> "$ZRC"
      grep -q "zsh-syntax-highlighting.zsh" "$ZRC" || \
        echo "source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$ZRC"
      grep -q "zoxide init" "$ZRC" || \
        echo 'eval "$(zoxide init zsh)"; alias cd="z"' >> "$ZRC"
      grep -q 'alias ls="eza' "$ZRC" || \
        echo 'alias ls="eza --icons=always"' >> "$ZRC"
      ok "merged blocks into $ZRC"
    else
      # Replace with the captured, known-good snapshot (backs up the live one
      # first so nothing is lost).
      if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        cp -f "$HOME/.zshrc" "$HOME/.zshrc.pre-bootstrap.$(date +%s).bak"
        warn "backed up existing ~/.zshrc before replacing"
      fi
      link "$REPO_ROOT/host/zshrc.droplet" "$HOME/.zshrc"
    fi

    # skills symlink (skills -> .agents/skills)
    link "$REPO_ROOT/.agents" "$HOME/.agents"
  fi

  # git identity.
  git config --global user.name  "Rajit Khanna" 2>/dev/null || true
  git config --global user.email "rajitskhanna@gmail.com" 2>/dev/null || true

  ok "dotfiles linked"
fi

# =============================================================================
# 3. AGENT SKILLS (opencode / agents)
# =============================================================================
if [[ "$DO_SKILLS" -eq 1 ]]; then
  log "installing agent skills"
  SKILLS_DIR="$REPO_ROOT/.agents/skills"
  if command -v ocx >/dev/null 2>&1 || command -v opencode >/dev/null 2>&1; then
    # skills-lock.json drives reproducible installs.
    if [[ -f "$REPO_ROOT/skills-lock.json" ]]; then
      (cd "$REPO_ROOT" && ocx skills sync 2>/dev/null) || \
      (cd "$REPO_ROOT" && opencode skills sync 2>/dev/null) || \
        warn "ocx/openccode skills sync not available; skills are vendored in .agents/skills"
    fi
  else
    warn "opencode CLI not found; skills are vendored at .agents/skills (install opencode-ai via npm -g)"
  fi
  ok "skills ready at $SKILLS_DIR"
fi

echo -e "\n${c_g}bootstrap complete.${c_n} restart your shell (or: exec zsh) to apply."
