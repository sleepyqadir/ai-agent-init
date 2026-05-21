# aiagent-init

A production-grade AI development setup for both **Claude Code** and **Cursor** — works on new and existing projects.

## What Makes This Different

| Feature | This repo | Typical setup |
|---|---|---|
| Platform support | Claude Code + Cursor | One platform only |
| Existing project support | Analyzes your codebase | Generic questions only |
| AI layer | Built-in (conditional) | Not covered |
| Stack profiles | TypeScript, Next.js, Python, Go, AI | 1-2 stacks |
| Security hook | 14 patterns, blocks writes | 9 patterns or none |
| Dependency audit | Auto-runs on manifest changes | Manual |
| Session close | Writes session notes, warns on loose ends | None |
| Agents / delegation | 11 specialists (Claude) / Task subagents (Cursor) | 4-6 generic |

---

## Quick Start

### 1. Install (one-time)

```bash
git clone git@github.com:ahsanahmed321/ai-agent-init.git ~/ai-agent-init
~/ai-agent-init/install.sh
```

Then open a **new terminal** (or run `source ~/.zshrc`) — the `aiagent-init` command will be available.

### 2. Run on any project

**Claude Code — new project:**
```bash
mkdir my-new-project && cd my-new-project
aiagent-init --claude .
# Open in Claude Code → run /project-setup
```

**Cursor — new project:**
```bash
mkdir my-new-project && cd my-new-project
aiagent-init --cursor .
# Open in Cursor → type: use the project-setup skill
```

**Existing project:**
```bash
cd ~/Projects/my-existing-project
aiagent-init --claude .    # or --cursor
# Choose [m] to merge (adds missing files, keeps your existing ones)
```

---

## Platform Support

### Claude Code (`--claude`)

Installs `.claude/` with:

| Layer | Count | Details |
|---|---|---|
| Rules | 9 | Always-loaded, ~550 tokens |
| Agents | 11 | Specialized sub-agents with tool/model constraints |
| Skills | 14 | On-demand multi-phase workflows |
| Commands | 5 | `/commit`, `/pr`, `/review`, `/plan`, `/ship` |
| Hooks | 5 | Security guard, bash guard, dependency audit, session start/close |

### Cursor (`--cursor`)

Installs `.cursor/` with:

| Layer | Count | Details |
|---|---|---|
| Rules | 9 | `.mdc` files, always-loaded or file-scoped |
| Skills | 19 | 14 workflows + 5 converted commands |
| Hooks | 5 | Adapted for Cursor's event model |

Claude's 11 agents map to Cursor's `generalPurpose`/`explore`/`shell` Task subagents, guided by the `task-delegation` rule and skills.

---

## What You Get

### Rules (always loaded)

| Rule | Purpose | Claude | Cursor |
|---|---|---|---|
| `coding-style` | Immutability, file limits, naming, composition | `.md` | `.mdc` |
| `security` | OWASP, injection prevention, secret management | `.md` | `.mdc` |
| `testing` | TDD, coverage, test patterns | `.md` | `.mdc` |
| `git` | Conventional commits, branch safety | `.md` | `.mdc` |
| `agent-use` / `task-delegation` | When to delegate to which agent/subagent | `.md` | `.mdc` |
| `output` | Structured change log, severity tiers | `.md` | `.mdc` |
| `performance` | Model selection, context management | `.md` | `.mdc` |
| `ops` | Env vars, migrations, deploy safety | `.md` | `.mdc` |
| `ai-patterns` | Prompt hygiene, cost, evals (AI projects only) | `.md` | `.mdc` |

### Agents — Claude Code only (11 specialists)

| Agent | Role | When triggered |
|---|---|---|
| `planner` | Implementation plans | Multi-file features, ambiguous requirements |
| `architect` | System design + ADRs | New systems, major refactors |
| `code-reviewer` | Quality + confidence scoring | After implementation |
| `security-auditor` | OWASP + STRIDE + CVEs | Auth changes, pre-merge |
| `work-verifier` | Comprehensive verification | Before declaring done |
| `debugger` | Root-cause investigation | Any bug |
| `database-reviewer` | Schema + migration + query safety | DB changes |
| `api-designer` | Contract-first API design | New endpoints |
| `ai-architect` | Orchestration + evals + cost | Any AI feature |
| `devops-reviewer` | CI/CD + Dockerfile + infra | Pipeline changes |
| `frontend-dev` | Build + Design + Polish to 10/10 | Frontend after backend ready |

### Skills (on-demand)

| Skill | Purpose | Claude | Cursor |
|---|---|---|---|
| `project-setup` | Setup new or analyze existing | `/project-setup` | `project-setup` skill |
| `feature-dev` | 7-phase feature development | `/feature-dev` | `feature-dev` skill |
| `api-design` | Contract-first API design | `/api-design` | `api-design` skill |
| `tdd` | Red-green-refactor TDD cycle | `/tdd` | `tdd` skill |
| `database-migrate` | Safe migration with rollback SQL | `/database-migrate` | `database-migrate` skill |
| `ai-agent-build` | Build AI agents with eval-first | `/ai-agent-build` | `ai-agent-build` skill |
| `debug` | Systematic root-cause debugging | `/debug` | `debug` skill |
| `ui-design` | Distinctive UI creation | `/ui-design` | `ui-design` skill |
| `e2e-testing` | Playwright E2E tests | `/e2e-testing` | `e2e-testing` skill |
| `e2e-loop` | Exploratory E2E testing loop | `/e2e-loop` | `e2e-loop` skill |
| `10-10-frontend` | Iterative UI polish via screenshots | `/10-10-frontend` | `10-10-frontend` skill |
| `ci-setup` | GitHub Actions workflow generation | `/ci-setup` | `ci-setup` skill |
| `new-skill` | Extend the system with custom skills | `/new-skill` | `new-skill` skill |
| `new-agent` / `new-rule` | Add agents (Claude) or rules (Cursor) | `/new-agent` | `new-rule` skill |
| `commit` | Conventional commit workflow | `/commit` command | `commit` skill |
| `pr` | PR creation with what/why/testing | `/pr` command | `pr` skill |
| `review` | Parallel code + security review | `/review` command | `review` skill |
| `plan` | Implementation planning | `/plan` command | `plan` skill |
| `ship` | Verify → review → commit → PR | `/ship` command | `ship` skill |

### Hooks (automated guards)

| Hook | Trigger | What it does | Claude event | Cursor event |
|---|---|---|---|---|
| `security-guard.py` | Before file write | Blocks 14 dangerous patterns | `PreToolUse: Edit\|Write` | `preToolUse: Write` |
| `bash-guard.py` | Before shell command | Blocks 14 dangerous patterns | `PreToolUse: Bash` | `beforeShellExecution` |
| `dependency-audit.sh` | After manifest change | CVE check, blocks on CRITICAL | `PostToolUse: Write` | `postToolUse: Write` |
| `session-start.sh` | Session open | Injects git context | `SessionStart` | `sessionStart` |
| `session-close.py` | Session end | Warns on loose ends, writes notes | `Stop` | `stop` |

---

## Token Budget (Claude Code)

| Layer | Tokens | Notes |
|---|---|---|
| Rules (9 files) | ~550 | Always loaded |
| Agent descriptions | ~700 | Always loaded (idle) |
| Skill descriptions | ~450 | Always loaded (idle) |
| **Total idle** | **~1,700** | Lean by design |

---

## Stack Profiles

The `project-setup` skill auto-selects a profile based on your stack:

- **TypeScript + Node.js** — camelCase, path aliases, Zod, ESLint + Prettier
- **Next.js + React** — App Router, Server Components first, Zod validation
- **Python + FastAPI** — snake_case, Pydantic, ruff, mypy, pytest-asyncio
- **Go** — error handling, context everywhere, golangci-lint, govulncheck
- **AI Project** — model config, prompt versioning, eval framework, cost tracking
- **Generic** — universal conventions for any stack

---

## Updating an Existing Project

Pull the latest agents, skills, rules, hooks, and commands:

```bash
# Claude Code
aiagent-init --update --claude .

# Cursor
aiagent-init --update --cursor .
```

This will:
1. Pull the latest template from GitHub
2. Overwrite the safe directories (agents/skills/rules/hooks/commands for Claude; skills/rules/hooks for Cursor)
3. Leave `CLAUDE.md` / `AGENTS.md` and platform config untouched

---

## Re-running Setup

Run `project-setup` again to:
- **New project:** re-interview and regenerate everything
- **Existing project:** re-analyze the codebase and update the context file

---

## Platform Mapping Reference

| Concept | Claude Code | Cursor |
|---|---|---|
| Config directory | `.claude/` | `.cursor/` |
| Project context file | `CLAUDE.md` | `AGENTS.md` |
| Rules format | `.md` (no frontmatter) | `.mdc` (with YAML frontmatter) |
| Rules location | `.claude/rules/` | `.cursor/rules/` |
| Skills location | `.claude/skills/` | `.cursor/skills/` |
| Slash commands | `.claude/commands/*.md` | Converted to skills with `disable-model-invocation: true` |
| Agents | `.claude/agents/*.md` (11 files) | Task subagents via `task-delegation` rule |
| Hook config | `.claude/settings.json` | `.cursor/hooks.json` |
| Hook env var | `CLAUDE_PROJECT_DIR` | `CURSOR_WORKSPACE_PATH` |
| Session notes | `.claude/session-notes.md` | `.cursor/session-notes.md` |
| MCP config | `.mcp.json.example` | `.cursor/mcp.json.example` |

---

## Extending

```
# Claude Code
/new-skill    → add a custom workflow skill
/new-agent    → add a specialized agent

# Cursor
new-skill skill    → add a custom workflow skill
new-rule skill     → add a persistent coding standard
```

Both skill guides walk you through creating well-structured extensions that integrate with the existing system.
