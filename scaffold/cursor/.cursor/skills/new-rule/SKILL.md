---
name: new-rule
description: Create a new persistent Cursor rule (.mdc file) for always-on coding standards or file-specific guidance.
---

# New Rule

Rules are persistent guidelines that load automatically in every session (or when matching files are open). They provide always-on context without needing to be invoked.

## When to Create a Rule (vs a Skill)

- **Rule**: Persistent guidance, always loaded. Example: `coding-style`, `security`, `git`
- **Skill**: Multi-phase workflow you invoke explicitly. Example: `feature-dev`, `api-design`

Create a rule when: you have standards or conventions that should always be followed, not just during specific tasks.

## Process

### Step 1: Define the Rule

Answer:
- What should this rule enforce or teach?
- Should it always apply, or only when specific files are open?
- If file-specific, which glob patterns? (e.g., `**/*.ts`, `src/api/**`)

### Step 2: Decide the Scope

**Always apply** — for universal standards:
```yaml
---
description: Core coding standards
alwaysApply: true
---
```

**File-specific** — for conventions tied to a file type or directory:
```yaml
---
description: TypeScript conventions
globs: **/*.ts
alwaysApply: false
---
```

### Step 3: Write the Rule

Create `.cursor/rules/[name].mdc`:

```markdown
---
description: Brief description of what this rule enforces
alwaysApply: true
---

## Rule Name

- Specific, actionable guideline
- Another guideline
- Concrete example:
  - ✅ Good: `getUserById(id)`
  - ❌ Bad: `getUser(id)`
```

### Step 4: Verify

- Is the rule under 500 lines? (ideally under 50)
- Does it have concrete examples where helpful?
- Is it focused on one concern?
- Does it avoid information already covered by existing rules?

## Rules
- Keep rules concise — one concern per rule
- Actionable and specific — write like internal team docs
- Avoid repeating content from existing rules (coding-style, security, testing, git, ops, output, performance, task-delegation, ai-patterns)
- Rules load every session — keep the token cost lean
