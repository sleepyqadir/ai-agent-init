---
name: review
description: Run parallel code quality and security review on current changes. Triggers: "review my code", "review changes", "code review", "security review", "review before merge".
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

   Per-file review:
   - **Correctness** — does it do what it claims? Edge cases and error paths handled?
   - **Consistency** — does it follow patterns already established in this codebase?
   - **Types** — all types accurate? No `any` or implicit casts?
   - **Error handling** — errors caught, typed, and handled appropriately?
   - **Tests** — coverage for both happy path and failure modes?
   - **Duplication** — could an existing utility be reused?
   - **Naming** — clear, accurate, consistent with conventions?
   - **Tautological tests** — do tests actually verify behavior, or just assert what the mock returns?

   Confidence scoring: only report findings with confidence ≥80%.

   **Security Review subagent** — provide the git diff and instruct it to:

   Run pattern scans:
   ```bash
   # SQL injection candidates
   grep -rn "query.*+\|execute.*+\|raw.*+" --include="*.ts" --include="*.py" .

   # Hardcoded secrets
   grep -rn "api_key\s*=\s*['\"][^'\"]\|secret\s*=\s*['\"][^'\"]" .

   # Dangerous functions
   grep -rn "eval(\|exec(\|os\.system(\|dangerouslySetInnerHTML\|innerHTML\s*=" .

   # Dependency audit
   npm audit --json 2>/dev/null || pip-audit 2>/dev/null || echo "No audit tool found"
   ```

   Check for OWASP Top 10:
   - **A01 Broken Access Control** — IDOR, missing auth checks, path traversal
   - **A02 Cryptographic Failures** — hardcoded secrets, weak algorithms, plaintext sensitive data
   - **A03 Injection** — SQL, command, XSS, template injection
   - **A04 Insecure Design** — missing rate limiting, unsafe defaults
   - **A07 Auth Failures** — weak session management, missing token expiry
   - **A10 SSRF** — unvalidated URLs, internal endpoint access

   Report with CWE references and specific fixes.

3. Wait for both to complete
4. Merge findings into a single report:
   - Lead with any Critical findings from either review
   - Then Improvements
   - Then Nitpicks
5. Give an overall verdict: APPROVED | REQUEST CHANGES

If `REQUEST CHANGES`: list exactly what must be fixed before merge.
