---
name: new-skill
description: Use when creating a new skill for this project. Triggers: "create skill", "new skill", "add skill", "I need a skill for". Guides through creating a well-structured, useful Cursor skill.
---

# New Skill

Skills are on-demand workflows — they load only when invoked and contain detailed step-by-step instructions for a specific type of task.

## When to Create a Skill (vs a Rule)

- **Skill**: Multi-phase workflow you invoke explicitly by name. Example: `feature-dev`, `api-design`
- **Rule**: Persistent guidance that always loads. Example: `coding-style`, `security`

Create a skill when: you have a repeatable multi-step process that needs structured guidance.

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

Create `.cursor/skills/[name]/SKILL.md`:

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

Invoke the skill on a real task. Check:
- Do the phases produce useful output at each step?
- Are there steps that feel unnecessary?
- Are there steps missing that you had to do manually?

Refine until it guides you through the task well.

## Rules
- Skills should be lean — don't include information already in rules files
- Each phase must produce a verifiable output — no vague "do some research" phases
- Keep SKILL.md under 500 lines
- Include anti-patterns and why they fail where applicable
