---
name: verify
description: Comprehensive verification that completed work is correct and production-ready. Runs tests, build, lint, checks requirements, scans for regressions and debug artifacts. Use before committing, shipping, or declaring non-trivial work done.
disable-model-invocation: true
---

# Verify

You are the final gate. Your job is to confirm completed work actually meets the original requirements and is production-ready. Be thorough. Be fast.

## Step 1 — Run verification commands

Launch a `generalPurpose` Task subagent to execute these commands (run them, do not estimate):

```
From AGENTS.md:
  - Project test command — all tests must pass
  - Project build command — must succeed
  - Project lint command — must pass (skip if not configured)

Always run:
  - grep -rn "console\.log\|debugger\|print(" . --include="*.js" --include="*.ts" --include="*.py" 2>/dev/null | grep -v node_modules | grep -v ".cursor"
  - git diff --stat HEAD
  - git diff HEAD (scan for unintended changes)
```

Subagent reports results back as raw command output. Do not interpret or estimate — only report what the commands returned.

## Step 2 — Complete the checklist

### Tests
- [ ] Test command ran and all tests passed
- [ ] New code has corresponding tests
- [ ] No skipped or disabled tests in changed files (grep for `skip(`, `xit(`, `pytest.mark.skip`)
- [ ] Test names describe expected behavior, not implementation

### Build
- [ ] Build command ran and succeeded without errors or warnings
- [ ] No TypeScript / type errors
- [ ] No compilation warnings introduced

### Code Quality
- [ ] Lint passed (or is not configured)
- [ ] No `console.log`, `print(`, `debugger` in production paths
- [ ] No `TODO` or `FIXME` without a tracking issue reference
- [ ] No `any` types in TypeScript projects
- [ ] No hardcoded secrets, tokens, or URLs that should be env vars

### Requirements
- [ ] Re-read the original user request
- [ ] Every stated acceptance criterion is met:
  ```
  AC-1: [criterion] — Verify: [result]
  AC-2: [criterion] — Verify: [result]
  ```
- [ ] No requirements silently dropped or partially implemented
- [ ] Edge cases mentioned in the request are handled

### Regressions
- [ ] Existing tests still pass (confirmed by test run above)
- [ ] No unintended changes in `git diff`
- [ ] API contracts maintained — no breaking changes unless explicitly intended

### Deploy Readiness
- [ ] New environment variables documented in `.env.example`
- [ ] Database migrations included if schema changed
- [ ] New dependencies added to package manifest
- [ ] No dev-only utilities in production code paths

## Step 3 — Report

Output the result as a table:

```
=== Work Verification ===

| Check            | Status          | Notes                    |
|------------------|-----------------|--------------------------|
| Tests            | PASS / FAIL     | [details]                |
| Build            | PASS / FAIL     | [details]                |
| Lint             | PASS / FAIL / N/A | [details]              |
| Requirements     | PASS / FAIL     | [missing: list]          |
| Regressions      | PASS / FAIL     | [details]                |
| Deploy readiness | PASS / FAIL     | [missing: list]          |

Issues found:
  [severity] [description]

Verdict: VERIFIED | NEEDS WORK
[If NEEDS WORK: exact list of what must be fixed before this is done]
```

## Rules

- Run actual commands via subagent. Do not read code and guess whether tests would pass.
- Never claim tests, builds, lint, or scans passed unless the command was actually executed and output confirmed success. If a command cannot be run, report it as `NOT VERIFIED` with the reason.
- Verify against the ORIGINAL request, not what was implemented.
- One failing check = NEEDS WORK. No exceptions, no partial passes.
- Check `git diff` for unintended changes before declaring complete.
- Check for placeholder implementations: stub functions, hardcoded return values, TODO comments without tracking references.

## When to Use

- Before using the `ship` skill
- Before using the `commit` skill for non-trivial work
- After implementing a feature, before declaring done
- When the user asks "is this ready?"
