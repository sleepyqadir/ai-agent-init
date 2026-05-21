---
description: Create a conventional commit after reviewing staged changes
---

Run a conventional commit on staged changes.

1. Run `git diff --staged` to review exactly what's being committed
2. If nothing is staged, run `git status` and stage the relevant files
3. Check for debug artifacts: `console.log`, `print(`, `debugger`, hardcoded secrets
4. If any found — stop and ask before proceeding
5. Write the commit message:
   - Format: `type(scope): description`
   - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
   - Imperative mood. Max 72 characters. No period at end.
   - If the change needs explanation: add a blank line then a body paragraph
6. Include co-author line if the project uses AI attribution: `Co-Authored-By: Claude <noreply@anthropic.com>`
7. Show the full commit message to the user before running git commit
8. Wait for confirmation, then commit
