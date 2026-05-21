---
name: plan
description: Create a step-by-step implementation plan before writing code for complex or ambiguous tasks.
disable-model-invocation: true
---

# Plan

Enter planning mode for the current task.

1. Read the user's request carefully — what are they actually asking for?
2. Launch a `generalPurpose` Task subagent with:
   - The full task description
   - Relevant file paths or context about the codebase
   - Instructions to produce a step-by-step implementation plan

   The subagent should follow this planning process:

   **Clarify requirements:**
   - Separate explicit requirements from inferred ones
   - List assumptions being made
   - Identify any critical ambiguities as questions — do not guess

   **Explore the codebase:**
   - Use Glob and Grep to find relevant files before reading them
   - Map what exists that the new work depends on
   - Identify the established patterns for similar features

   **Break into steps** — each step must be:
   - 2–5 minutes of focused work — not hours, not vague
   - Self-contained — verifiable on its own
   - Ordered — dependencies come before dependents
   - Specific — exact file paths and function names

   Step format:
   ```
   Step N: [action] [specific target]
     Files:   [exact paths to create or modify]
     How:     [approach in 1–2 sentences]
     Risk:    LOW | MEDIUM | HIGH
     Verify:  [how to confirm this step is correct]
     Needs:   [step numbers this depends on, or "none"]
   ```

   **For features spanning backend + frontend**, produce a typed JSON contract defining all endpoints, request/response shapes, and shared types before any implementation begins.

   **Execution order:**
   - Group steps that can run in parallel
   - Identify the critical path
   - Flag steps that need user input before proceeding

3. Present the plan to the user
4. Wait for approval or revision requests before any implementation begins

Use this before any task that:
- Touches more than 2 files
- Has ambiguous requirements
- Involves architecture decisions
- Could have multiple valid approaches
