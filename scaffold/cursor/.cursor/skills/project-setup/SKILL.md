---
name: project-setup
description: Set up Cursor for a new or existing project and generate AGENTS.md from codebase analysis or interview.
---

# Project Setup

You set up Cursor for a project. You handle two modes automatically.

## Mode Detection

Before asking anything, check the current directory and one level deep:

```bash
ls -la
test -d .git && echo "has git"
test -f package.json && echo "has package.json"
test -f requirements.txt && echo "has requirements.txt"
test -f go.mod && echo "has go.mod"
test -f pyproject.toml && echo "has pyproject.toml"
test -f Cargo.toml && echo "has Cargo.toml"
test -d src && echo "has src"
test -d app && echo "has app"
ls */package.json */requirements.txt */go.mod */pyproject.toml 2>/dev/null | head -5
```

**EXISTING PROJECT if ANY of these are true:**
- `.git` exists at root
- `package.json`, `requirements.txt`, `go.mod`, `pyproject.toml`, `Cargo.toml` exists at root
- `src/` or `app/` exists at root
- Any of the above found in an immediate subdirectory

**Otherwise:**
→ NEW PROJECT mode

---

## MODE A: NEW PROJECT

Ask these questions ONE AT A TIME. Wait for each answer before asking the next.

1. **Project name** — What will this project be called?
2. **Project type** — Web app, REST API, CLI tool, library, AI system, or mobile app?
3. **Tech stack** — What language, framework, and database? (e.g. TypeScript + Express + PostgreSQL)
4. **Source structure** — What will the main source directories be? (e.g. src/routes, src/services)
5. **Domain** — Describe what this project does in 1–2 sentences.
6. **Deployment** — Where will this run? (Vercel, Railway, AWS, GCP, Docker, VPS)
7. **AI involved?** — Does this project call LLMs, build agents, or involve AI pipelines? (yes/no)
8. **Team or solo?** — Working alone or with other developers?
9. **MCP integrations** — Do you need GitHub, database, Sentry, Linear, or Slack MCP servers?
10. **CI/CD** — Do you want a GitHub Actions workflow generated? (yes/no)
11. **Evolution protocol** — Should Cursor proactively suggest new skills as gaps appear? (yes/no)

Store all answers before proceeding to generation.

### Generation Steps

**Step 1** — Read template files:
- `.cursor/skills/project-setup/templates/philosophy.md`
- `.cursor/skills/project-setup/templates/workflow-rules.md`
- `.cursor/skills/project-setup/templates/verification.md`
- If AI involved: `.cursor/skills/project-setup/templates/ai-layer.md`

**Step 2** — Read the matching stack profile:
- TypeScript/Node → `.cursor/skills/project-setup/profiles/typescript-node.md`
- Next.js/React → `.cursor/skills/project-setup/profiles/nextjs.md`
- Python/FastAPI → `.cursor/skills/project-setup/profiles/python-fastapi.md`
- Python/Django → `.cursor/skills/project-setup/profiles/django.md`
- Go → `.cursor/skills/project-setup/profiles/go.md`
- Rust → `.cursor/skills/project-setup/profiles/rust.md`
- AI project → `.cursor/skills/project-setup/profiles/ai-project.md`
- Other → `.cursor/skills/project-setup/profiles/generic.md`

**Step 3** — Assemble AGENTS.md with these sections:
```
# [Project Name]

[domain description — 1–2 sentences]

## Quick Start
[commands to install, run dev, run tests, run build]

## Architecture
[directory structure with purpose of each folder]

## Tech Stack
[language, framework, database, key libraries]

## Development Conventions
[from stack profile — naming, imports, patterns]

## Philosophy
[from philosophy template]

## Core Workflow Rules
[from workflow-rules template]

## Development Rules
[NEVER / ALWAYS lists adapted to this stack]

## Verification
[from verification template]

[If AI involved: ## AI Patterns — from ai-layer template]

[If evolution enabled: ## Evolution Protocol]
```

**Step 4** — If MCP integrations selected, create `.cursor/mcp.json.example` with relevant server configs:
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

**Step 5** — If CI/CD requested, invoke the `ci-setup` skill.

**Step 6** — Print summary (see Summary section below).

---

## MODE B: EXISTING PROJECT

Do NOT ask generic questions. Analyze the codebase first, then ask only what you couldn't determine.

### Analysis Steps

**Step 1 — Detect stack:**
```bash
cat package.json 2>/dev/null | head -50
cat requirements.txt 2>/dev/null
cat pyproject.toml 2>/dev/null | head -20
cat go.mod 2>/dev/null | head -20
cat Cargo.toml 2>/dev/null | head -20
find . -maxdepth 2 -name "package.json" -o -name "requirements.txt" -o -name "pyproject.toml" -o -name "go.mod" -o -name "Cargo.toml" 2>/dev/null | grep -v node_modules | head -10
# Detect Django vs FastAPI (both are Python)
grep -r "django" requirements.txt pyproject.toml 2>/dev/null | head -3
grep -r "fastapi" requirements.txt pyproject.toml 2>/dev/null | head -3
```

Stack detection rules:
- `Cargo.toml` present → Rust profile
- `requirements.txt` or `pyproject.toml` with `django` → Django profile
- `requirements.txt` or `pyproject.toml` with `fastapi` → Python/FastAPI profile
- `go.mod` present → Go profile
- `package.json` with Next.js dependency → Next.js profile
- `package.json` without Next.js → TypeScript/Node profile
- LLM/AI packages detected → AI project profile (can combine with above)
- None of the above → Generic profile

**Step 2 — Understand architecture:**
```bash
find . -maxdepth 3 -type d | grep -v node_modules | grep -v .git | grep -v __pycache__
```

**Step 3 — Infer conventions from git history:**
```bash
git log --oneline -20
git log --format="%s" -10
```

**Step 4 — Check what already exists:**
```bash
test -f AGENTS.md && echo "has AGENTS.md"
test -f CLAUDE.md && echo "has CLAUDE.md"
test -d .cursor && echo "has .cursor"
test -d .claude && echo "has .claude"
test -d .github/workflows && echo "has CI"
find . -name "*.test.*" -o -name "*.spec.*" | head -5
```

**Step 5 — Read a few key files** (pick 2–3 most relevant):
- Main entry point (index.ts, main.py, main.go, app.py)
- One route/handler file to understand patterns
- One test file to understand test conventions

**Step 6 — Produce Gap Report:**

```
=== Project Analysis ===

Detected:
  Stack:      [detected stack]
  Framework:  [detected framework]
  Test tool:  [detected test framework]
  CI/CD:      [found | not found]
  .cursor/:   [found | not found]

Conventions inferred:
  Commit format: [conventional | other pattern detected]
  Naming:        [camelCase | snake_case | mixed]
  Test location: [colocated | __tests__ | tests/]

Gaps vs best practices:
  Missing: [list — e.g. no CI, no test coverage threshold, no security scanning]
  Present: [list — what's already well set up]
```

**Step 7 — Ask only what analysis couldn't determine:**
- Domain description (1 sentence — hard to infer from code)
- Deployment target (if no CI/CD config found)
- AI involved? (if no LLM packages detected)
- Evolution protocol on/off?

**Step 8 — Confirm before writing:**

Show what will be created/modified. Wait for user confirmation.

**Step 9 — Generate AGENTS.md** based on actual codebase analysis, not generic templates.

**Step 10** — If `.cursor/` exists, MERGE — add only what's missing, never overwrite existing files.

---

## Summary (both modes)

After completing setup, print:

```
=== Setup Complete ===

AGENTS.md         — generated for [project name]
Rules (9)         — coding-style, security, testing, git, task-delegation, output, performance, ops
                    [+ ai-patterns if AI project]
Skills            — [list of available skills]

Available now:
  feature-dev     — 7-phase feature development
  api-design      — design endpoints before building
  tdd             — test-driven development
  database-migrate — safe migration workflow
  debug           — systematic root-cause debugging
  ui-design       — distinctive UI creation
  e2e-testing     — Playwright test generation
  e2e-loop        — automated exploratory E2E testing
  ci-setup        — GitHub Actions workflow generation
  10-10-frontend  — iterative UI polish to 10/10
  [ai-agent-build — if AI project]
  plan            — implementation planning
  review          — parallel code + security review
  commit          — conventional commit workflow
  pr              — pull request creation
  ship            — verify → review → commit → PR pipeline
  new-skill       — extend the system
  new-rule        — add persistent coding standards
```
