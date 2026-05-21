---
name: e2e-testing
description: Use when writing end-to-end tests for a web application. Triggers: "E2E tests", "Playwright tests", "end-to-end", "integration tests for the UI", "browser tests". Reconnaissance first — map all routes before writing a single test.
---

# E2E Testing

Understand the app before testing it. Tests that don't know the app test the wrong things.

## Phase 1: Reconnaissance

Before writing any test:
```bash
# Find all routes
grep -rn "route\|path\|href" src/ --include="*.tsx" --include="*.ts" | grep -v test
# Or read the router config directly
```

Map every route and categorize:
- Public (no auth)
- Authenticated (requires login)
- Admin / role-gated

List the critical user journeys — the paths that, if broken, immediately break the product.

## Phase 2: Setup

```bash
# Install Playwright if not present
npx playwright install --with-deps

# Check for existing test config
ls playwright.config.*
```

Create `e2e/` at the project root if it doesn't exist.
Create `e2e/helpers/auth.ts` for saving and reusing authentication state.

## Phase 3: Write Tests — Critical Journeys First

Order:
1. Authentication flow (signup, login, logout)
2. Core feature flow (the thing users do most)
3. Error flows (form validation, not-found, unauthorized)
4. Edge cases last

Each test file = one user journey.

```typescript
// e2e/auth.spec.ts
test('user can sign up, log in, and log out', async ({ page }) => {
  // Sign up
  await page.goto('/signup')
  await page.fill('[name=email]', 'test@example.com')
  await page.fill('[name=password]', 'Password123!')
  await page.click('[type=submit]')
  await expect(page).toHaveURL('/dashboard')

  // Log out
  await page.click('[data-testid=user-menu]')
  await page.click('[data-testid=logout]')
  await expect(page).toHaveURL('/login')
})
```

## Test Quality Rules

- "Page loads" is NOT a test. Click buttons. Fill forms. Verify outcomes.
- Empty states need seed data — insert before testing, not just accept "no data"
- Test what the user sees and does — not implementation details
- Each test is independent — no relying on state from previous tests
- Use `data-testid` attributes for test selectors — never CSS class names (they change)

## Phase 4: CI Integration

Add to your CI workflow:
```yaml
- name: Run E2E tests
  run: npx playwright test
  env:
    BASE_URL: http://localhost:3000
```

Start the app before running tests, or use Playwright's `webServer` config.

## Rules
- Reconnaissance before any test code
- Seed data for tests that need data — never just skip empty state
- One user journey per test file
- `data-testid` for all selectors
