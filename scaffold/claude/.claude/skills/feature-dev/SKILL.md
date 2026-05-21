---
name: feature-dev
description: Implement a multi-file feature through a 7-phase workflow — explore, design, implement, review. No code before Phase 5.
---

# Feature Development

## Mode Selection

Before starting, assess the scope:

**Lite Mode** — use when ALL of these are true:
- Touches 1–2 files
- No public API changes
- No auth/security/payment changes
- No database migrations
- Requirements are clear (no ambiguity)

Lite Mode steps:
1. Read the relevant file(s)
2. Make the minimal change
3. Run targeted tests
4. Summarize what changed

**Full Mode** — use for everything else. All 7 phases. Skipping phases causes rework.

---

## Phase 1: Define
- State the feature in one sentence
- List explicit acceptance criteria (what does "done" look like?)
- Estimate scope: which modules, how many files?

## Phase 2: Explore
Dispatch the `architect` agent, or do manually:
- Find relevant existing code with Glob and Grep — read before writing
- Trace the execution path the feature will touch
- Identify patterns already used for similar features
- List every file that will need modification

## Phase 3: Clarify
Before writing a line — resolve ambiguities:
- Ask about unclear requirements
- Propose approaches for technical decisions
- Confirm acceptance criteria

Do NOT proceed until all questions are answered.

## Phase 4: Design
Produce an implementation blueprint:
- New files to create (exact paths + purpose)
- Existing files to modify (exactly what changes)
- Interface design (function signatures, types, data shapes)
- Test strategy (what to test, what not to test)

Present to user. Wait for approval.

## Phase 5: Implement
Execute the approved design:
- Create and modify files in the order the design specifies
- Follow TDD: failing test → implementation → verify
- Use the output format: filepath, purpose, dependencies, exposes

## Phase 6: Review
Self-review before declaring done:
- Dispatch `code-reviewer` for quality
- Dispatch `security-auditor` if any auth, API, or data handling changed
- Run full test suite
- Verify all acceptance criteria from Phase 1

## Phase 7: Wrap Up
- Summarize what was built (1 paragraph)
- List all files created or modified
- Note any follow-up work or known limitations

## Rules
- NEVER skip Phase 2 (Explore) — understanding the codebase prevents bad architecture
- NEVER skip Phase 3 (Clarify) — assumptions cause rework
- NEVER write code before Phase 5 — design first
- NEVER skip Phase 6 (Review) — unreviewed code has defects
- If scope grows during implementation, stop and re-scope with the user
