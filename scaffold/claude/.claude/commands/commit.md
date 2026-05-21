---
description: Stage and commit changes with conventional commit format, checking for debug artifacts first.
---

Run a conventional commit on staged changes.

## Auth Preflight

Run silently before committing. Surface output only on failure:
1. Set `GIT_TERMINAL_PROMPT=0` to prevent password hangs
2. If GPG signing is configured, verify it: `echo "test" | gpg --clearsign > /dev/null 2>&1` — if fails, ask whether to use `--no-gpg-sign` or stop

## Steps

1. Run `git diff --staged` to see what's staged
2. If nothing staged, run `git status` and stage relevant files with `git add <files>`
3. Scan for debug artifacts: `console.log`, `print(`, `debugger`, hardcoded secrets — stop and list findings if found
4. Write the commit message:
   - Format: `type(scope): description`
   - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
   - Imperative mood. Max 72 chars. No trailing period.
   - Add a body paragraph only when the *why* isn't obvious from the subject
5. Show a one-line status + the commit message, then ask to confirm:
   ```
   N files staged. No artifacts found.

   feat(scope): short description

   Body if needed.

   Confirm?
   ```
6. On confirmation: `GIT_TERMINAL_PROMPT=0 git commit -m "..."`
7. Report result: `Committed <short-hash> — <subject>`

## Output Rules

- Skip preamble — no "Let me check...", "I'll now..."
- Summarize staged files in one line, not file-by-file
- Show the commit message in a code block for easy copy
- After committing: one line only — `Committed <hash> — <subject>`
- Issues (artifacts, auth failure): state the problem, stop — no hedging
