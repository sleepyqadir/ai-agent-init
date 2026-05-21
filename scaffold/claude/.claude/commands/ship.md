---
disable-model-invocation: true
description: Verify, review, commit, and create a PR in one user-triggered workflow
---

Prepare and ship the current work: verify → commit → PR.

1. **Verify** — delegate to `work-verifier` agent
   - Tests pass, build succeeds, lint clean
   - Requirements met, no regressions
   - If verdict is NEEDS WORK: stop here and fix before proceeding

2. **Review** — run `/review`
   - Code quality and security review in parallel
   - If REQUEST CHANGES: stop here and fix before proceeding

3. **Commit** — run `/commit`
   - Stage all relevant changes
   - Write conventional commit message
   - Show to user for confirmation

4. **PR** — run `/pr`
   - Draft PR with what/why/testing sections
   - Show to user for confirmation
   - Create PR with `gh pr create`

5. **Confirm** — show user the PR URL

Do not skip steps. Each gate exists because skipping it causes production incidents.
