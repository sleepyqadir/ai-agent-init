---
description: Enter plan mode and produce a step-by-step implementation plan before writing code. Use for tasks touching 3+ files, ambiguous requirements, or architecture decisions.
---

Enter plan mode and create a structured implementation plan for the current task.

## Step 1 — Enter Plan Mode

Press `Shift+Tab` twice (or type `/plan`) to enter Plan mode. Plan mode is read-only — you can explore the codebase, ask questions, and design, but no files are written. This separation prevents premature commitment before the full scope is understood.

If you are already in a long session, run `/compact` first to free context budget for codebase exploration.

## Step 2 — Delegate to the Planner Agent

Delegate to the `planner` agent with:
- The full task description restated in your own words
- Specific file paths or areas of the codebase that are relevant
- Any constraints the user mentioned (performance, compatibility, conventions)
- The expected output: a structured plan following the planner's output format

The planner will:
1. Clarify requirements — separating explicit from inferred, listing assumptions
2. Explore the codebase — mapping dependencies, consumers, and established patterns
3. Design the approach — comparing alternatives, identifying risks
4. Break into ordered, verifiable steps with exact file paths
5. Produce an execution order with parallelism and critical path

## Step 3 — Review the Plan

When the planner returns, review the output before presenting:

**Quality checklist:**
- [ ] Every step has exact file paths, not vague module references
- [ ] Steps are 2–5 minutes of work each, not hour-long blocks
- [ ] Dependencies between steps are explicit
- [ ] Risk is assessed for each step, especially shared/critical code
- [ ] At least 3 risks are identified for the overall plan
- [ ] Verification method is concrete (a command, a test, a check) not "verify it works"

If the plan fails the checklist, ask the planner to revise before presenting.

## Step 4 — Present and Iterate

Present the plan to the user with this structure:

```
## Plan: [title]

Goal: [one sentence]
Approach: [2–3 sentences — what and why]
Alternatives considered: [what was rejected and why]

Requirements:
- [R1] explicit — [description]
- [R2] inferred (assumption: ...) — [description]

Questions (if any):
- [Q1]

Steps:
[step list from planner]

Execution order:
[phases with parallel/sequential grouping]

Risks:
- [risk — what could go wrong, how to mitigate]

Overall risk: LOW | MEDIUM | HIGH
```

Stay in plan mode to iterate. If the user wants changes, revise the plan — do not exit plan mode until the user approves.

## Step 5 — Save and Execute

Once approved:
- Suggest saving the plan to `.claude/plans/` for future context and team reference
- Exit plan mode (`Shift+Tab` to return to normal mode)
- Follow the plan step by step
- If something unexpected comes up during implementation, re-enter plan mode to revise rather than improvising

## When to Use

- Task touches 3+ files
- Requirements are ambiguous
- Architecture decisions are involved
- Multiple valid approaches exist
- You think "this might also affect..."

## When NOT to Use

- One-line fix or trivial rename
- Well-understood task touching 1–2 files
- User explicitly asks to skip planning

## For Large Projects (10+ files, multi-day scope)

Consider using `/ultraplan` instead — it runs a dedicated Opus 4.6 session in the cloud for up to 30 minutes, providing deeper analysis for architectural-scale planning. Requires a GitHub repository and Claude Code web account.
