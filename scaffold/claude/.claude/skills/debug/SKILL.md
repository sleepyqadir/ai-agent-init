---
name: debug
description: |
  Use when investigating a bug, failing test, or unexpected behavior.
  Triggers: "why is this failing", "debug", "investigate", "root cause", stack traces, error output.
  Investigates before fixing. Never jumps to a solution without evidence.
---

# Debug

Find the root cause. Then fix it. In that order.

## Phase 1: Reproduce

- Get the exact error message and stack trace
- State in one sentence: what SHOULD happen vs what DOES happen
- Can you reproduce it consistently? If not, what conditions trigger it?

## Phase 2: Check the Obvious First

Before deep investigation, check the most common failures by category:

**If the frontend is broken:**
- Component exists but has no logic wired up? (29.7% of frontend failures)
- Button/form does nothing on click? (23.7%)
- Dev server won't start? Check the terminal for errors
- Data fetching fails? Check the network tab — URL, CORS headers, auth header
- Form submits but server rejects? Check request payload shape vs API expectation

**If the backend is broken:**
- Endpoint returns hardcoded data instead of querying the DB? (34.3% of backend failures)
- Endpoint is a stub? (33.3%)
- Can't connect to DB? Check connection string, check if migrations ran, check if DB is running
- Service won't start? Check for port conflicts, missing env vars

**If the database is broken:**
- Tables exist but no rows? Add seed data
- Missing columns? Check if latest migration ran
- Missing tables? Run migrations

## Phase 3: Gather Evidence

- Read the failing code path end-to-end — do not guess
- Check recent git history: `git log --oneline -20`, `git diff HEAD~5`
- Use binary search for long paths: add assertion at midpoint, narrow to the failing half

## Phase 4: Hypothesize

- Write 2–3 concrete hypotheses
- For each: what evidence confirms or refutes it?
- Rubber duck: explain the code flow step-by-step. Explanation often reveals the flaw.

## Phase 5: Test Hypotheses

- Add minimal diagnostics (a log, an assertion) — do NOT change production code yet
- Test one hypothesis at a time
- Record the result
- Eliminate disproven hypotheses

## Phase 6: Fix

- Write a failing test that captures the bug BEFORE fixing it
- Apply the minimal fix — change as little as possible
- The failing test must now pass
- Run the full suite — no regressions
- Remove all temporary diagnostics

## Rules

- Never apply a fix without first reproducing the bug
- Never make multiple changes at once during investigation
- Never skip the failing test before the fix
- Never leave temporary debug code in the commit
