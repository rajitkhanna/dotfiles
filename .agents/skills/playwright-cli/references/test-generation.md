# Test Generation

Generate Playwright test code by interacting with the browser via `playwright-cli`.

## Workflow

```bash
playwright-cli open https://example.com/login
playwright-cli snapshot
playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "password123"
playwright-cli click e3
```

Collect emitted Playwright code and place it in a test file.

## Example Test

```typescript
import { test, expect } from '@playwright/test';

test('login flow', async ({ page }) => {
  await page.goto('https://example.com/login');
  await page.getByRole('textbox', { name: 'Email' }).fill('user@example.com');
  await page.getByRole('textbox', { name: 'Password' }).fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();

  await expect(page).toHaveURL(/.*dashboard/);
});
```

## Tips

- Prefer semantic locators over fragile CSS selectors
- Snapshot first to understand element refs
- Add assertions manually; generated code focuses on actions
