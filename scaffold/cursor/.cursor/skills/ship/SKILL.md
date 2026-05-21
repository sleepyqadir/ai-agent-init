---
name: ship
description: Full pipeline to verify, review, commit, and create a PR for the current work.
disable-model-invocation: true
---

# Ship

Prepare and ship the current work: verify → review → commit → PR.

## Auth Preflight

Run before anything else. Surface output only on failure:
1. `gh auth status` — if fails, tell user to run `gh auth login` and stop
2. `git remote get-url origin` — if SSH, run `ssh -T git@github.com 2>&1 || true` — warn if fails
3. Set `GIT_TERMINAL_PROMPT=0` for all git operations

## Steps

1. **Verify** — launch a `generalPurpose` Task subagent to run these commands (run them, do not estimate):
   - Project test command (from AGENTS.md)
   - Project build command
   - Project lint command (if available)
   - `grep -rn "console\.log\|debugger\|print(" .` for debug artifacts
   - `git diff` for unintended changes
   - Check `.env.example` updated if new env vars added
   - Check migrations included if schema changed

   Subagent reports a compact status line:
   ```
   Tests: PASS | Build: PASS | Lint: PASS | Artifacts: none | Unintended changes: none
   Verdict: VERIFIED
   ```
   If NEEDS WORK: stop and fix before proceeding.

2. **Review** — use the `review` skill. If REQUEST CHANGES: stop and fix.

3. **Commit** — use the `commit` skill (includes auth preflight, artifact check, confirmation).

4. **PR** — use the `pr` skill (includes auth preflight, test check, confirmation).

5. Report the PR URL.

## Output Rules

- No narration between phases — no "Now moving to review...", "Let me now..."
- Each gate: state what failed and stop, or proceed to the next phase
- Final output: PR URL only

Do not skip steps. Each gate exists because skipping it causes production incidents.
