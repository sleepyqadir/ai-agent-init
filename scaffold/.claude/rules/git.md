## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`. Imperative mood. Max 72 chars.
- One logical change per commit. Refactors and features in separate commits.
- Branch naming: `feat/short-description`, `fix/issue-id`, `refactor/area`.
- Never commit directly to main/master. Always through a branch and PR.
- Never force-push to shared branches. Never amend published commits.
- Before committing: tests pass, no debug statements, no secrets, no unintended files.
- PR title follows conventional commits format. Body explains the why, not the what.
- Co-author line on every commit: `Co-Authored-By: Claude <noreply@anthropic.com>`
- Do NOT commit or push unless the user explicitly asks.
