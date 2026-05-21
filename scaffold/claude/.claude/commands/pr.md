---
description: Create a pull request for the current branch after reviewing commits and tests
---

Create a pull request for the current branch.

1. Run `git log main..HEAD --oneline` to see all commits in this branch
2. Run `git diff main...HEAD` to see all changes
3. Confirm tests pass: run the project's test command (check CLAUDE.md for the exact command)
4. Write the PR:
   - Title: conventional commits format, max 70 chars
   - Body:
     ```
     ## What
     [1-3 bullet points — what changed]

     ## Why
     [The reason for the change — what problem it solves]

     ## Testing
     - [ ] Tests pass
     - [ ] [Specific things a reviewer should test manually]

     ## Notes
     [Anything the reviewer should know — breaking changes, follow-ups, caveats]
     ```
5. Check for breaking changes — flag them explicitly in Notes
6. Show the full PR draft to the user before creating
7. Wait for approval, then run `gh pr create`
