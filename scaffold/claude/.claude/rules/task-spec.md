## Task Specification

Before writing code for any non-trivial task, establish a clear definition of done.

**When to apply:** Any task that touches 2+ files, involves ambiguity, or has behavior implications. Skip for single-file typo fixes or obvious one-liners.

**Required before coding:**

State these three things, even briefly:
- **Goal:** What outcome are we achieving? (one sentence)
- **Acceptance criteria:** What must be true when this is done? Use the canonical format:
  ```
  AC-1: [criterion] — Verify: [exact command or check]
  AC-2: [criterion] — Verify: [exact command or check]
  ```
- **Out of scope:** What are we explicitly NOT doing? (prevents scope creep)

**For complex tasks (3+ files, architecture decisions, ambiguous requirements):** Invoke the `/plan` command instead. The plan skill enforces this format with full step-by-step breakdown, risk assessment, and execution order.

**Verification honesty:** Never mark acceptance criteria as met without running the verification command. "I think it passes" is not verification.

**Why this matters:** Without an explicit definition of done, the agent invents its own — and it's always weaker than what you actually needed.
