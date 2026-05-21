---
name: new-skill
description: Create a new on-demand Claude Code skill for a repeatable multi-step workflow.
---

# New Skill

Skills are on-demand workflows — they load only when invoked and contain detailed step-by-step instructions for a specific type of task.

## When to Create a Skill (vs a Command or Agent)

- **Skill**: Multi-phase workflow you invoke explicitly by name. Example: `feature-dev`, `api-design`
- **Command**: Quick slash command for a single action. Example: `/commit`, `/pr`
- **Agent**: A specialized worker you delegate tasks to. Example: `code-reviewer`, `planner`

Create a skill when: you have a repeatable multi-step process that needs guidance.

## Process

### Step 1: Name and Purpose

- Name: `kebab-case`, descriptive of the task (not the tool)
- One sentence: what problem does this skill solve?
- When should someone use it? (triggers)

### Step 2: Identify the Phases

Break the skill into 3–7 phases. Each phase:
- Has a clear goal
- Produces a concrete output
- Can be verified before proceeding to the next

### Step 3: Write the Skill

Create `.claude/skills/[name]/SKILL.md`:

```markdown
---
name: [skill-name]
description: |
  [1-2 sentence description]
  Triggers: [comma-separated list of trigger phrases]
  [What it produces]
---

# [Skill Name]

[One-line summary of what this skill does]

## Phase 1: [Name]
[What to do in this phase]

## Phase 2: [Name]
[What to do in this phase]

## Rules
- [Critical constraints — what must never be skipped]
```

### Step 4: Test It

Run `/[skill-name]` on a real task. Check:
- Do the phases produce useful output at each step?
- Are there steps that feel unnecessary?
- Are there steps missing that you had to do manually?

Refine until it guides you through the task well.

## Rules
- Skills should be lean — don't include information already in rules files
- Each phase must produce a verifiable output — no vague "do some research" phases
- Include anti-patterns and why they fail (the RATIONALIZATION TABLE pattern works well)
