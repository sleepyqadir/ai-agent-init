---
description: Create a pull request for the current branch after reviewing commits and running tests.
---

Create a pull request for the current branch.

## Auth Preflight

Run before any git/gh operation. Surface output only on failure:
1. `gh auth status` — if fails, tell user to run `gh auth login` and stop
2. `git remote get-url origin` — if SSH remote, run `ssh -T git@github.com 2>&1 || true` — warn if auth fails
3. Set `GIT_TERMINAL_PROMPT=0` for all git operations to prevent password hangs

## Steps

1. Run `git log main..HEAD --oneline` to see branch commits
2. Run `git diff main...HEAD --stat` for a change summary (not the full diff)
3. Run the project's test command (check CLAUDE.md) — if tests fail, stop and report
4. Draft the PR:
   - Title: conventional commits format, max 70 chars
   - Body:
     ```
     ## What
     [1-3 bullet points — what changed]

     ## Why
     [The reason for the change — what problem it solves]

     ## Testing
     - [ ] Tests pass
     - [ ] [Specific things a reviewer should manually verify]

     ## Notes
     [Breaking changes, follow-ups, caveats — omit section if none]
     ```
5. Show the PR title + body only, ask to confirm
6. On confirmation: `gh pr create --title "..." --body "..."`
7. Report: `PR created: <URL>`

## Output Rules

- Skip preamble — no "Let me check the commits...", "I'll now..."
- Use `--stat` not full diff — do not list every changed line
- Show only the PR title + body for confirmation, nothing else
- After creating: one line — `PR created: <URL>`
- Tests fail or auth fails: state the problem and stop
