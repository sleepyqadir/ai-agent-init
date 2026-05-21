## Verification

Every task has a verification step. "It looks right" is not verification.

### After Implementation
1. Run the full test suite — all tests must pass
2. Run the build — no errors, no new warnings
3. Run the linter — no violations
4. Grep for debug artifacts: `console.log`, `print(`, `debugger`, `TODO`, `FIXME`
5. Check against the original request — not what was built, but what was asked for

### Before Declaring Done
- Did I address every requirement in the original request?
- Are edge cases handled?
- Would the `work-verifier` agent pass this?

When uncertain: delegate to `work-verifier`.

### Before Committing
- `git diff` — review every changed line
- No secrets, no debug statements, no unintended file changes
- Tests pass, build succeeds
- Commit message follows conventions
