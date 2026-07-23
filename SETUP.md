# SETUP.md

Purpose:
- Give this to an agent to bootstrap a machine with this dotfiles repo.
- Covers installing CLI tools, linking configs, and (optionally) wiring Google Workspace via the `gws` CLI using a refresh token copy flow.

## How to use (agent)

- Clone the repo to `~/dotfiles` (or wherever you prefer).
- Run the agent-owned `bootstrap.sh` (it detects OS and installs the full toolchain).
- If you want Google Workspace (gws) on a headless server, export a credential from an already-authed machine and copy it to the server (see section below).
- Do NOT commit or paste secrets into chat. Only store credentials in `~/.config/gws/credentials.json` on each machine.

## Machine setup (manual)

1) Clone and bootstrap

```bash
git clone https://github.com/rajitkhanna/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
exec zsh
```

- On Linux, if you do not want the live `~/.zshrc` replaced, use `--safe`:

```bash
./bootstrap.sh --safe
```

2) Google Workspace (gws) — headless/SSH setup (no browser needed on the server)

- On a desktop with browser where `gws` is already authed:

```bash
gws auth export --unmasked > ~/gws-creds.json
```

- Copy the credential file to the server and place it where gws expects:

```bash
scp ~/gws-creds.json root@hermes:/root/.config/gws/credentials.json
```

- Verify on the server:

```bash
gws auth status
gws gmail users getProfile --params '{"userId":"me"}'
```

Notes:
- `gws auth export --unmasked` prints a standard `authorized_user` JSON with a long-lived refresh token.
- Keep this file private and never commit it to git or paste it into chat.
- `gws auth logout` revokes access.

## Agent prompt (copy/paste)

- The following is a safe, agent-run prompt that performs the above steps (without using any stored secrets in chat). It tells the agent to handle credentials only on the target machine.

```
You are setting up a new machine from the dotfiles repo:
https://github.com/rajitkhanna/dotfiles.git

Goal:
- Install all CLI tools and link dotfiles.
- Optionally set up Google Workspace (gws) on headless servers via a refresh token copy flow (no browser required on the server).

Requirements:
- Detect OS (Ubuntu/Debian or macOS) and install the full CLI toolchain.
- Link dotfiles safely. On Linux, preserve the current ~/.zshrc unless explicitly told to replace it; prefer the `--safe` merge mode.
- For Google Workspace:
  - If the machine is headless, instruct the user to run `gws auth export --unmasked` on an already-authed machine, then copy the resulting file to `~/.config/gws/credentials.json` on the target server.
  - Verify gws works with `gws auth status` and a simple API call.
  - Do NOT ask the user to paste credentials into chat. Do not store credentials in the repo or logs.

Steps to run:
1) Clone the repo to `~/dotfiles`
2) Run `./bootstrap.sh` (use `--safe` on Linux if you want to preserve the current `~/.zshrc`)
3) If setting up Google Workspace on a headless server:
   - Instruct the user to export credentials from an authed machine:
     `gws auth export --unmasked > ~/gws-creds.json`
   - Copy the file securely to the target server:
     `scp ~/gws-creds.json root@TARGET:/root/.config/gws/credentials.json`
   - Verify:
     `gws auth status`
     `gws gmail users getProfile --params '{"userId":"me"}'`
4) Report the installed tools, linked dotfiles, and gws auth status.

Constraints:
- Never commit or print secrets.
- Prefer existing scripts in the repo (bootstrap.sh) over custom one-offs.
- Keep changes minimal and idempotent.
- If something fails, provide the exact failing command and likely cause.
```

## Notes

- The repo vendors a set of `gws-*` skills under `.agents/skills/` (Sheets, Docs, Gmail, Drive).
- The `bootstrap.sh` script installs `@googleworkspace/cli` automatically on both Linux and macOS.
- Auth requires a one-time browser OAuth. For headless servers, use the refresh-token copy flow described above.
