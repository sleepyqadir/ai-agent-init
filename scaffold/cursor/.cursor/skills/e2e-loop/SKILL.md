---
name: e2e-loop
description: Use when doing automated exploratory E2E testing on a running web application. Triggers: "exploratory testing", "test this app", "find bugs", "e2e loop", "run e2e tests". Maps the app, then tests every page deeply — clicks buttons, fills forms, verifies database state.
---

# E2E Loop (Exploratory Testing)

You become the tester. You navigate a running web app with Playwright, interact with everything, and document bugs in a structured report. You do not skip pages. You do not accept "page loads" as a passing test.

## Phase 1: Map the Application

### Discover Routes

Based on framework — detect from `package.json` or directory structure:

**Next.js App Router:**
```bash
find . -name "page.tsx" -path "*/app/*" | grep -v node_modules | sort
```

**Next.js Pages Router:**
```bash
find . -name "*.tsx" -path "*/pages/*" | grep -v "_app\|_document\|api/" | sort
```

**React Router / Vite / other:**
Search for `createBrowserRouter`, `<Route`, or route config patterns.

### Categorize Each Route

For each route, note:
- Type: list | detail | form | dashboard | settings | auth
- Interactive elements: buttons, forms, modals, tabs, dropdowns
- Needs data: does this page require database records to be meaningful?

### Ask the User (before generating anything)

1. App URL (e.g., `http://localhost:3000`)
2. Login credentials for testing
3. Known issues (these become mandatory test cases)

### Group Routes into Phases

One phase = one logical page group = one test iteration.

```
Phase 1: Auth (login, signup, logout)
Phase 2: Dashboard (main overview)
Phase 3: [Core feature] list and detail
Phase 4: [Core feature] create and edit
...
Phase N: Cross-cutting (mobile 375px, forms, navigation, error states)
```

### Create Test Infrastructure

Create `e2e-results/` directory:
- `phase-tracker.md` — checkbox per phase
- `FINDINGS.md` — structured bug report
- `playwright-helper.ts` — reusable browser utilities (auth, screenshots, navigation)

## Phase 2: Setup

```bash
npm install -D playwright @playwright/test
npx playwright install chromium
```

Save auth state before running tests:
```typescript
// playwright-helper.ts
await page.goto('/login');
await page.fill('[name=email]', email);
await page.fill('[name=password]', password);
await page.click('[type=submit]');
await page.context().storageState({ path: 'e2e-results/auth.json' });
```

Smoke test — verify the app is reachable and login works before proceeding.

## Phase 3: Test Each Phase

For each phase (one at a time, mark complete before moving on):

### Per Page Type — Minimum Depth

**List page:**
- Verify items display (if empty, insert seed data first — do not accept empty as passing)
- Verify items match database records
- Click at least one item
- Test empty state with no data

**Detail page:**
- Verify all fields render
- Click every action button
- Document what each action does

**Form page:**
- Fill ALL fields
- Submit
- Verify success UI
- **Verify database record was created/updated**
- Test validation (submit empty, submit invalid data)

**Delete action:**
- Trigger delete
- Confirm dialog if present
- **Verify record removed from database**

**Dashboard:**
- Verify metric values are accurate (not hardcoded)
- Check for stale or misleading data

### Database Validation

After every mutation (create, update, delete) through the UI:
1. Query the database directly
2. Confirm the record exists / was updated / was deleted
3. Confirm all fields match what was submitted

Document any mismatch as a `no-db-interaction` finding.

### API Validation

For each discovered endpoint:
1. Hit it directly (curl or fetch)
2. Verify correct status code on valid input
3. Verify error response (400, not 500) on invalid input
4. Confirm database state changed after mutations

## Phase 4: Report

After all phases complete, produce `FINDINGS.md`:

```
# E2E Test Findings

Summary:
  Phases tested: N
  Critical: N
  Major: N
  Minor: N

## Critical Findings
### [CATEGORY] [Page: /route] [Title]
Steps to reproduce:
  1.
  2.
Expected: 
Actual:
Evidence: [screenshot path or error message]

## Major Findings
[same structure]

## Minor Findings
[same structure]
```

Use these tags on every finding:

Frontend: `functionality-not-implemented` | `unresponsive-component` | `data-fetch-failure` | `form-error` | `missing-module`

Backend: `no-db-interaction` | `api-not-implemented` | `db-setup-error` | `connection-failed`

Database: `db-empty` | `fields-missing` | `tables-missing`

## Quality Rules

1. **"Page loads" is not a test.** Every phase must click buttons, fill forms, verify outcomes.
2. **Empty pages need data.** Insert seed data before testing lists. "No data shown" is not a pass.
3. **User-reported issues are truth.** Never dismiss as "design decision." Document as requirement gap.
4. **Test mobile.** The cross-cutting phase must include a 375px viewport pass.
5. **Database round-trips are mandatory.** Every mutation test must verify the DB state.
6. **Write .ts files.** Complex Playwright scripts must be `.ts` files — not inline bash strings.
7. **Evidence required.** Screenshot before AND after every interaction. Log what was clicked.

## Anti-Patterns

| What to avoid | Why | What to do instead |
|---|---|---|
| "Page renders — pass" | Rendering is not testing | Click every button, fill every form |
| "No data — working as expected" | Empty state hides bugs | Insert data, re-test |
| "This looks like a design choice" | Dismisses user requirements | Document as requirement gap |
| Skipping the database check | Misses #1 backend failure | Always verify DB state after mutations |
