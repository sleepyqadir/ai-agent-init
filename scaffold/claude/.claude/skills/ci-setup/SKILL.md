---
name: ci-setup
description: Generate a GitHub Actions CI/CD workflow with test, lint, build, and optional deploy gates.
---

# CI Setup

A pipeline that doesn't gate on test failures is decoration.

## Phase 1: Understand the Project

Read:
- `package.json` / `requirements.txt` / `go.mod` → detect language and tools
- Existing `.github/workflows/` → understand what already exists
- Deployment target (from CLAUDE.md or user input)

Confirm:
- Test command
- Build command
- Lint command
- Deploy target (Vercel, Railway, AWS, GCP, Docker, none)

## Phase 2: Generate the Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Cache dependencies (saves 2-5 min per run)
      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: |
            ~/.npm
            node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: tsc --noEmit

      - name: Test
        run: npm test

      - name: Build
        run: npm run build
```

For deploy jobs, add AFTER the test job succeeds:
```yaml
  deploy:
    name: Deploy
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      # Stack-specific deploy step
```

## Phase 3: Security Hardening

Add to the workflow:
```yaml
permissions:
  contents: read
  # Add only what the workflow actually needs
```

Check:
- All secrets accessed via `${{ secrets.SECRET_NAME }}` — never hardcoded
- Third-party actions pinned to SHA (not mutable tags)
- No `git push` or deployment from PR events on forks

## Phase 4: Document Required Secrets

List every secret the workflow needs in `.github/SECRETS.md` (or update CLAUDE.md):
```
Required GitHub Secrets:
  VERCEL_TOKEN         — Vercel deployment token
  DATABASE_URL         — Production database URL (for migrations)
  [etc]
```

## Phase 5: Test the Workflow

Push to a branch and verify:
- Lint step runs and catches violations
- Test step catches a failing test
- Build step fails on build errors
- Deploy only triggers on main

## Rules
- Tests must gate deploy. Always. Non-negotiable.
- Secrets in `${{ secrets.* }}` only — never in env vars set inline
- Cache dependencies — it makes CI fast enough to actually use
- Delegate to `devops-reviewer` for complex infrastructure review
