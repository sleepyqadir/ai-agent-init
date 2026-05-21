---
name: commit
description: Create a conventional commit after reviewing staged changes. Triggers: "commit", "commit my changes", "create a commit", "stage and commit". Reviews staged changes for debug artifacts and secrets before committing.
disable-model-invocation: true
---

# Commit

Run a conventional commit on staged changes.

1. Run `git diff --staged` to review exactly what's being committed
2. If nothing is staged, run `git status` and stage the relevant files
3. Check for debug artifacts: `console.log`, `print(`, `debugger`, hardcoded secrets
4. If any found — stop and ask before proceeding
5. Write the commit message:
   - Format: `type(scope): description`
   - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
   - Imperative mood. Max 72 characters. No period at end.
   - If the change needs explanation: add a blank line then a body paragraph explaining WHY
6. Show the full commit message to the user before running git commit
7. Wait for confirmation, then commit
