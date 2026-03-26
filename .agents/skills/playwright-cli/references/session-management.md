# Browser Session Management

Run multiple isolated browser sessions concurrently with state persistence.

## Named Sessions

```bash
playwright-cli -s=auth open https://app.example.com/login
playwright-cli -s=public open https://example.com

playwright-cli -s=auth fill e1 "user@example.com"
playwright-cli -s=public snapshot
```

Each session has independent cookies, storage, cache, tabs, and history.

## Session Commands

```bash
playwright-cli list
playwright-cli close
playwright-cli -s=mysession close
playwright-cli close-all
playwright-cli kill-all
playwright-cli delete-data
playwright-cli -s=mysession delete-data
```

## Persistent Profiles

```bash
playwright-cli open https://example.com --persistent
playwright-cli open https://example.com --profile=/path/to/profile
```

## Default Session via Env

```bash
export PLAYWRIGHT_CLI_SESSION="mysession"
playwright-cli open https://example.com
```

## Best Practices

- Use semantic session names (`checkout-auth`, `admin-review`)
- Close sessions after runs
- Use `kill-all` only for stuck daemons
- Delete stale data periodically with `delete-data`
