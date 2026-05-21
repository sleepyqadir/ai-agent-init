---
description: Create a step-by-step implementation plan before writing code for complex or ambiguous tasks.
---

Enter planning mode for the current task.

1. Read the user's request carefully — what are they actually asking for?
2. Delegate to the `planner` agent with:
   - The full task description
   - Any relevant context about the codebase
   - The expected output format
3. The planner will explore the codebase, clarify requirements, and produce a step-by-step implementation plan
4. Present the plan to the user
5. Wait for approval or revision requests before any implementation begins

Use this before any task that:
- Touches more than 2 files
- Has ambiguous requirements
- Involves architecture decisions
- Could have multiple valid approaches
