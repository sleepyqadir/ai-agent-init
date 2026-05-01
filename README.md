# claude-project-init

A 10/10 Claude Code setup that works for both new and existing projects.

## What Makes This Different

| Feature | This repo | Typical setup |
|---|---|---|
| Existing project support | Analyzes your codebase | Generic questions only |
| AI layer | Built-in (conditional) | Not covered |
| Stack profiles | TypeScript, Next.js, Python, Go, AI | 1-2 stacks |
| Security hook | 14 patterns, blocks writes | 9 patterns or none |
| Dependency audit | Auto-runs on manifest changes | Manual |
| Session close | Writes session notes, warns on loose ends | None |
| Agents | 11 specialized agents | 4-6 generic |

## Quick Start

### 1. Install (one-time)

```bash
git clone https://github.com/ahsanahmed321/claude-project-init ~/.claude-templates/project-init
```

Add the alias for your shell:

```bash
# zsh
echo 'alias claude-init="~/.claude-templates/project-init/bootstrap.sh"' >> ~/.zshrc && source ~/.zshrc

# bash
echo 'alias claude-init="~/.claude-templates/project-init/bootstrap.sh"' >> ~/.bashrc && source ~/.bashrc
```

### 2. Run on any project

**New project:**
```bash
mkdir my-new-project && cd my-new-project
claude-init .
# Open in Claude Code → run /project-setup
```

**Existing project:**
```bash
cd ~/Projects/my-existing-project
claude-init .
# Choose [m] to merge (adds missing files, keeps your existing ones)
# Open in Claude Code → run /project-setup
# Claude will analyze your codebase and generate CLAUDE.md from what it finds
```

## What You Get

### Rules (always loaded, ~550 tokens)

| Rule | Purpose |
|---|---|
| `coding-style` | Immutability, file limits, naming, composition |
| `security` | OWASP, injection prevention, secret management |
| `testing` | TDD, coverage, test patterns |
| `git` | Conventional commits, branch safety |
| `agent-use` | When to delegate to which agent |
| `output` | Structured file headers, severity tiers |
| `performance` | Model selection, context management |
| `ops` | Env vars, migrations, deploy safety |
| `ai-patterns` | Prompt hygiene, cost, evals (AI projects only) |

### Agents (11 specialists)

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

| Skill | Purpose |
|---|---|
| `/project-setup` | Setup new or analyze existing — main entry point |
| `/feature-dev` | 7-phase feature development (explore → design → build → review) |
| `/api-design` | Contract-first API design before any implementation |
| `/tdd` | Red-green-refactor TDD cycle |
| `/database-migrate` | Safe migration with rollback SQL and danger detection |
| `/ai-agent-build` | Build AI agents with eval-first discipline |
| `/debug` | Systematic root-cause debugging |
| `/ui-design` | Distinctive UI — not generic AI output |
| `/e2e-testing` | Playwright E2E tests, recon-first |
| `/ci-setup` | GitHub Actions workflow generation |
| `/new-skill` | Extend the system with custom skills |
| `/new-agent` | Add specialized agents |

### Commands

| Command | Purpose |
|---|---|
| `/commit` | Conventional commit with safety checks |
| `/pr` | PR with what/why/testing sections |
| `/review` | Parallel code + security review |
| `/plan` | Delegate to planner agent |
| `/ship` | Verify → review → commit → PR in one step |

### Hooks

| Hook | Trigger | What it does |
|---|---|---|
| `security-guard.py` | Before every file write | Blocks 14 dangerous patterns |
| `dependency-audit.sh` | After package manifest changes | CVE check, blocks on CRITICAL |
| `session-close.py` | Session end | Warns on loose ends, writes session notes |

## Token Budget

| Layer | Tokens | Notes |
|---|---|---|
| Rules (9 files) | ~550 | Always loaded |
| Agent descriptions | ~700 | Always loaded (idle) |
| Skill descriptions | ~450 | Always loaded (idle) |
| **Total idle** | **~1,700** | Lean by design |

## Stack Profiles

The `/project-setup` skill auto-selects a profile based on your stack:

- **TypeScript + Node.js** — camelCase, path aliases, Zod, ESLint + Prettier
- **Next.js + React** — App Router, Server Components first, Zod validation
- **Python + FastAPI** — snake_case, Pydantic, ruff, mypy, pytest-asyncio
- **Go** — error handling, context everywhere, golangci-lint, govulncheck
- **AI Project** — model config, prompt versioning, eval framework, cost tracking
- **Generic** — universal conventions for any stack

## Re-running Setup

Run `/project-setup` again to:
- New project: re-interview and regenerate everything
- Existing project: re-analyze the codebase and update CLAUDE.md

Existing `.claude/` files are backed up before overwrite.

## Extending

```
/new-skill    → add a custom workflow skill
/new-agent    → add a specialized agent
```

Both skills guide you through creating well-structured extensions that integrate with the existing system.
