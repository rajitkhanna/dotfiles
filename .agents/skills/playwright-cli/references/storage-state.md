# Storage Management

Manage cookies, localStorage, sessionStorage, and full browser storage state.

## Save / Restore State

```bash
playwright-cli state-save
playwright-cli state-save auth.json
playwright-cli state-load auth.json
```

## Cookies

```bash
playwright-cli cookie-list
playwright-cli cookie-list --domain=example.com
playwright-cli cookie-get session_id
playwright-cli cookie-set session abc123 --domain=example.com --path=/ --httpOnly --secure
playwright-cli cookie-delete session_id
playwright-cli cookie-clear
```

## Local Storage

```bash
playwright-cli localstorage-list
playwright-cli localstorage-get token
playwright-cli localstorage-set theme dark
playwright-cli localstorage-delete token
playwright-cli localstorage-clear
```

## Session Storage

```bash
playwright-cli sessionstorage-list
playwright-cli sessionstorage-get step
playwright-cli sessionstorage-set step 3
playwright-cli sessionstorage-delete step
playwright-cli sessionstorage-clear
```

## Auth Reuse Pattern

```bash
playwright-cli open https://app.example.com/login
playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "password123"
playwright-cli click e3
playwright-cli state-save auth.json

playwright-cli state-load auth.json
playwright-cli open https://app.example.com/dashboard
```

## Security Notes

- Never commit auth state files
- Prefer in-memory sessions for sensitive flows
- Delete state files after automation is done
