---
description: Run parallel code quality and security review on current changes before merging.
---

Run a full parallel code and security review on current changes.

1. Run `git diff HEAD` to identify what changed
2. Dispatch two agents in parallel:
   - `code-reviewer` — quality, correctness, tests, patterns, lint
   - `security-auditor` — OWASP, injection, secrets, dependencies
3. Wait for both to complete
4. Merge findings into a single report using this format:

   ```
   file.ts L42: bug — <problem>. <fix>.
   file.ts L88-140: nit — <problem>. <fix>.
   file.ts L15: risk — <problem>. <fix>.

   Tests: PASS | Lint: PASS
   Verdict: APPROVED | REQUEST CHANGES
   ```

   Lead with bug findings first, then risk, then nit.

5. If REQUEST CHANGES: list exactly what must be fixed before merge.

## Output Rules

- Each finding is one line: `file:line: severity — problem. fix.`
- No hedging — state findings directly
- No restating what the code does — only what's wrong and how to fix it
- Verdict is always explicit: APPROVED or REQUEST CHANGES
