---
name: ship
description: Verify, review, commit, and create a PR in one user-triggered workflow. Triggers: "ship this", "ship my work", "ship it", the full ship pipeline.
disable-model-invocation: true
---

# Ship

Prepare and ship the current work: verify → review → commit → PR.

1. **Verify** — launch a `generalPurpose` Task subagent to run the verification checklist:

   The subagent must actually run these commands (not estimate):
   - Run the project's test command (check AGENTS.md) — all tests pass
   - Run the project's build command — builds without errors or warnings
   - Run the project's lint command — passes (if available)
   - Check for debug artifacts: `console.log`, `print(`, `debugger`, `TODO`, `FIXME`
   - Check `git diff` for unintended changes
   - Verify new environment variables are documented in `.env.example`
   - Confirm database migrations are included if schema changed

   Output format:
   ```
   === Work Verification ===
   | Check            | Status       | Notes     |
   | Tests            | PASS / FAIL  | [details] |
   | Build            | PASS / FAIL  | [details] |
   | Lint             | PASS / FAIL / N/A | [details] |
   | Requirements     | PASS / FAIL  | [missing] |
   | Deploy readiness | PASS / FAIL  | [missing] |

   Verdict: VERIFIED | NEEDS WORK
   ```

   If verdict is NEEDS WORK: stop here and fix before proceeding.

2. **Review** — use the `review` skill
   - Code quality and security review in parallel
   - If REQUEST CHANGES: stop here and fix before proceeding

3. **Commit** — use the `commit` skill
   - Stage all relevant changes
   - Write conventional commit message
   - Show to user for confirmation

4. **PR** — use the `pr` skill
   - Draft PR with what/why/testing sections
   - Show to user for confirmation
   - Create PR with `gh pr create`

5. **Confirm** — show user the PR URL

Do not skip steps. Each gate exists because skipping it causes production incidents.
