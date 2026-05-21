---
name: new-agent
description: Create a new specialized Claude Code agent with a focused role, defined tools, and explicit output contract.
---

# New Agent

Agents are specialized workers — they run in isolated context with specific tools and a single clear job.

## When to Create an Agent (vs a Skill)

- **Agent**: A specialist you delegate to. It does the work and reports back. Example: `code-reviewer`, `database-reviewer`
- **Skill**: A workflow you follow step-by-step yourself. Example: `feature-dev`, `api-design`

Create an agent when: you have a focused task that benefits from a fresh context window and defined tool access.

## Process

### Step 1: Define the Role

- What is the one job this agent does?
- What triggers it? (what condition should cause delegation to this agent?)
- What does it produce? (exact output format)
- What tools does it actually need? (least privilege)
- Which model? (cheapest that meets quality bar)

### Step 2: Write the Agent

Create `.claude/agents/[name].md`:

```markdown
---
name: [agent-name]
description: |
  [Role description]
  Auto-trigger: [condition that should trigger this agent]
  [What it outputs]
tools: [Read, Grep, Glob, Bash — only what's needed]
model: [haiku | sonnet | opus]
---

# [Agent Name]

[One-line role description]

## Process

### 1. [Phase name]
[What to do]

### 2. [Phase name]
[What to do]

## Output

[Exact output format — use a code block showing the structure]

## Rules
- [What the agent must always do]
- [What the agent must never do]
```

### Step 3: Add to agent-use.md

Add a row to the agent delegation table in `.claude/rules/agent-use.md`:
```
| [agent-name] | [trigger condition] |
```

### Step 4: Test It

Invoke the agent on a real task:
- Does it do exactly the one job it was designed for?
- Does it use only the tools it needs?
- Is the output format consistent and useful?

## Rules
- Each agent does ONE job. Multi-job agents are hard to test and reason about.
- Give agents the minimum tools they need. Read-only agents should not have Write.
- Model selection: use the cheapest model that produces acceptable quality.
- Always add the agent to agent-use.md after creating it.
