## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`. Imperative mood. Max 72 chars.
- Breaking changes: append `!` after type/scope (`feat(api)!:`) and include `BREAKING CHANGE:` footer with migration path.
- One logical change per commit. Refactors and features in separate commits. Never mix formatting with logic changes.
- Commit body: add only when the subject alone doesn't explain the motivation. Max 2 sentences — never bullet lists, never file-by-file changelogs. Explain WHY, not what — the diff shows what changed.
- Commit message must accurately reflect the actual diff. Never use superlatives ("comprehensive", "robust", "complete overhaul").
- Branch naming: `feat/short-description`, `fix/issue-id`, `refactor/area`.
- Never commit directly to main/master. Always through a branch and PR.
- Never force-push to shared branches. Never amend published commits.
- Stage files explicitly by name. Avoid `git add .` or `git add -A` which can catch unintended files.
- Before committing: tests pass, no debug statements, no secrets, no unintended files.
- PR title follows conventional commits format. Body explains the why, not the what.
- Add AI co-author attribution when the project or user uses that convention: `Co-Authored-By: Claude <noreply@anthropic.com>`
- Do NOT commit or push unless the user explicitly asks.
