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

Use an `explore` Task subagent for broad reconnaissance, or do manually:
- Find relevant existing code with Glob and Grep — read before writing
- Trace the execution path the feature will touch
- Identify patterns already used for similar features
- List every file that will need modification

For architecture decisions, use a `generalPurpose` Task subagent with the following context:
- The design problem
- Current codebase patterns discovered in exploration
- Non-negotiable constraints (latency, cost, team familiarity)

The architecture output should include: options considered with pros/cons, recommended approach, and an ADR if it's a significant decision.

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

Run parallel reviews via Task subagents:

**Code Review** — launch a `generalPurpose` subagent with:
- The git diff or list of changed files
- Project test/lint commands from AGENTS.md
- Instructions to run tests and lint before reviewing

Code review checklist:
- Correctness — does it do what it claims? Edge cases handled?
- Consistency — does it follow established codebase patterns?
- Types — no `any`, no implicit casts
- Error handling — errors caught, typed, handled appropriately
- Tests — happy path and failure modes covered
- No tautological tests (don't just assert what the mock returns)
- Confidence threshold: only report findings with ≥80% confidence

**Security Review** — launch a second `generalPurpose` subagent in parallel:
- Check for injection risks (SQL, command, eval)
- Check for hardcoded secrets
- Check IDOR / object-level authorization on any new data-access endpoints
- Check CORS, XSS, and SSRF risks where applicable
- Run dependency audit if manifests changed

If either review returns REQUEST CHANGES: stop and fix before proceeding.

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
