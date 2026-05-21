---
name: plan
description: Switch to Cursor's Plan mode to explore, design, and produce a step-by-step implementation plan before writing code. Use when a task touches 3+ files, has ambiguous requirements, or involves architecture decisions. Do NOT use for one-line fixes or trivial changes.
disable-model-invocation: true
---

# Plan

Switch to Cursor's Plan mode and produce a structured implementation plan.

## Step 1 — Enter Plan Mode

**Immediately** call `SwitchMode`:
```
SwitchMode(target_mode_id: "plan", explanation: "Entering plan mode to design the approach before writing code.")
```

Plan mode is read-only — you can explore the codebase, ask questions, and design, but no files are written until the user approves and switches back to Agent mode. This separation prevents premature commitment to an approach before the full scope is understood.

## Step 2 — Clarify Requirements

Before exploring code, understand what is actually being asked:

- Restate the user's goal in one sentence
- Separate **explicit** requirements (stated directly) from **inferred** ones (implied by context)
- List every assumption you are making — label each one
- If critical ambiguities exist, ask the user before proceeding — do not guess

If the request is vague, use `AskQuestion` to present structured choices rather than open-ended questions.

## Step 3 — Explore the Codebase

Use read-only tools to map the relevant parts of the codebase:

- **Glob** to find files by pattern before reading
- **Grep** to find specific symbols, types, or patterns
- **Read** the key files — focus on interfaces, types, and module boundaries
- For broad reconnaissance across many files, launch an `explore` subagent

Build a mental map of:
- What exists that the new work depends on
- What will consume or be affected by the new work
- The established patterns for similar features in this codebase
- Any constraints (framework conventions, existing abstractions, shared types)

## Step 4 — Design the Approach

Before breaking into steps, describe the high-level approach:

- What approach are you taking and **why**?
- What alternatives did you consider and why were they rejected?
- What are the key architectural decisions?
- What are the **three highest-risk** parts of this plan?

For features spanning backend + frontend, produce a typed contract first:

```
Contract:
  Endpoints:
    - METHOD /path → request shape → response shape
  Shared types:
    - TypeName { field: type }
  Database changes:
    - table.column (type) — reason
```

## Step 5 — Break Into Steps

Each step must be:
- **2–5 minutes of focused work** — not hours, not vague
- **Self-contained** — verifiable on its own
- **Ordered** — dependencies come before dependents
- **Specific** — exact file paths and function names, not "update the auth module"

Step format:
```
Step N: [action verb] [specific target]
  Files:   [exact paths to create or modify]
  How:     [approach in 1–2 sentences]
  Risk:    LOW | MEDIUM | HIGH — [why if MEDIUM or HIGH]
  Verify:  [exact command or check to confirm correctness]
  Needs:   [step numbers this depends on, or "none"]
```

**Risk rules:**
- Touching shared code, auth, payments, or data mutations → at least MEDIUM
- New patterns not established in the codebase → MEDIUM
- Schema changes or migrations → HIGH
- Pure additions with no existing dependencies → LOW

## Step 6 — Execution Order

- Group steps that can run in parallel (no dependencies between them)
- Identify the critical path (longest sequential chain)
- Flag steps that need user input or approval before proceeding
- For large plans (8+ steps), organize into named phases

```
Phase 1 — Foundation
  Step 1, Step 2 (parallel)
  Step 3 (depends on 1)

Phase 2 — Core Logic
  Step 4 (depends on 3)
  Step 5, Step 6 (parallel, depend on 4)
```

## Step 7 — Present and Iterate

Present the full plan with this structure:

```
## Plan: [title]

**Goal:** [one sentence]

**Approach:** [2–3 sentences on the chosen approach and why]

**Alternatives considered:**
- [approach] — rejected because [reason]

**Requirements:**
- [R1] explicit — [description]
- [R2] inferred (assumption: [what you assumed]) — [description]

**Questions (if any):**
- [Q1]

**Steps:**
[step list from Step 5]

**Execution order:**
[from Step 6]

**Risks:**
- [risk 1 — what could go wrong and how to mitigate]
- [risk 2]

**Overall risk: LOW | MEDIUM | HIGH**
```

Stay in Plan mode to iterate. If the user wants changes, revise the plan — do not switch to Agent mode until the user explicitly approves.

## Step 8 — Save and Execute

Once approved:
- Suggest saving the plan to `.cursor/plans/` for team reference and future context
- Switch to Agent mode only after explicit user approval
- Follow the plan step by step — if something unexpected comes up during implementation, pause and revisit the plan rather than improvising

## When to Use This Skill

**Use when:**
- Task touches 3+ files
- Requirements are ambiguous or underspecified
- Architecture decisions are needed
- Multiple valid approaches exist
- You find yourself thinking "this might also affect..."

**Do NOT use when:**
- One-line fix or trivial rename
- Task is well-understood and touches 1–2 files
- User explicitly asks to skip planning

## Anti-Patterns

- **Vague steps** like "update the auth module" — be specific about which files and functions
- **Planning simple tasks** — a 2-minute fix does not need a 10-step plan
- **Skipping exploration** — never plan from assumptions; read the actual code first
- **Starting implementation before approval** — the plan is a contract; honor it
- **Ignoring risk** — every plan should identify what could go wrong
