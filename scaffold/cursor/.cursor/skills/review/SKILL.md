---
name: review
description: Run parallel code quality and security review on current changes before merging.
disable-model-invocation: true
---

# Review

Run a full parallel code and security review on current changes.

1. Run `git diff HEAD` to identify what changed
2. Launch two `generalPurpose` Task subagents in parallel:

   **Code Review subagent** — provide the git diff and instruct it to:

   Preflight:
   - Run the project's test command (find it in AGENTS.md, `package.json`, `Makefile`, or `pyproject.toml`)
   - Run the project's lint command if one exists
   - Grep for debug artifacts: `console.log`, `debugger`, `print(`, `TODO`, `FIXME`
   - If tests fail → report REQUEST CHANGES immediately

   Per-file review (confidence ≥80% only):
   - **Correctness** — does it do what it claims? Edge cases and error paths handled?
   - **Consistency** — does it follow patterns already established in this codebase?
   - **Types** — all types accurate? No `any` or implicit casts?
   - **Error handling** — errors caught, typed, and handled appropriately?
   - **Tests** — coverage for happy path and failure modes? No tautological tests?
   - **Duplication** — could an existing utility be reused?
   - **Naming** — clear, accurate, consistent with conventions?

   **Security Review subagent** — provide the git diff and instruct it to:

   Run pattern scans:
   ```bash
   grep -rn "query.*+\|execute.*+\|raw.*+" --include="*.ts" --include="*.py" .
   grep -rn "api_key\s*=\s*['\"][^'\"]\|secret\s*=\s*['\"][^'\"]" .
   grep -rn "eval(\|exec(\|os\.system(\|dangerouslySetInnerHTML\|innerHTML\s*=" .
   npm audit --json 2>/dev/null || pip-audit 2>/dev/null || echo "No audit tool found"
   ```

   Check OWASP Top 10: A01 (broken access control), A02 (crypto failures), A03 (injection), A04 (insecure design), A07 (auth failures), A10 (SSRF). Report with CWE references and specific fixes.

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
- No hedging ("I noticed...", "you might want to...") — state findings directly
- No restating what the code does — only what's wrong and how to fix it
- Verdict is always explicit: APPROVED or REQUEST CHANGES
