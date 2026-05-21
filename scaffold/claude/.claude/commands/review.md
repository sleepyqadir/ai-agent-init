---
description: Run parallel code and security review on current changes
---

Run a full parallel code and security review on current changes.

1. Run `git diff HEAD` to identify what changed
2. Dispatch two agents in parallel:
   - `code-reviewer` — quality, correctness, tests, patterns
   - `security-auditor` — OWASP, injection, secrets, dependencies
3. Wait for both to complete
4. Merge findings into a single report:
   - Lead with any Critical findings from either agent
   - Then Improvements
   - Then Nitpicks
5. Give an overall verdict: APPROVED | REQUEST CHANGES

If `REQUEST CHANGES`: list exactly what must be fixed before merge.
