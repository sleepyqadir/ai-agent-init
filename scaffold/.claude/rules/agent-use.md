## Agent Delegation

Delegate proactively when trigger conditions are met. Do not wait to be asked.

| Agent | When to trigger |
|---|---|
| `planner` | Multi-file features, ambiguous requirements, anything touching 3+ modules |
| `architect` | New system design, major refactor, technology decision |
| `code-reviewer` | After implementing a feature, before declaring done |
| `security-auditor` | Auth changes, API changes, dependency updates, pre-merge |
| `work-verifier` | Before shipping, committing, or declaring non-trivial implementation done |
| `debugger` | Any bug investigation — never jump to a fix without investigation |
| `database-reviewer` | Schema changes, new migrations, query optimization |
| `api-designer` | New endpoints — design the contract before any implementation |
| `ai-architect` | Any task involving LLM integration, agent design, or AI orchestration |
| `devops-reviewer` | CI/CD changes, Dockerfile changes, deployment config changes |
| `frontend-dev` | Frontend build after backend is ready — wires to real APIs, applies distinctive design, polishes to 10/10 |

When delegating: give the agent focused context, exact file paths, and a specific output format. Never dump the whole conversation — summarize what's relevant.

After implementation, fan out review agents in parallel: `code-reviewer` + `security-auditor` + `database-reviewer` (if schema changed) + `devops-reviewer` (if infra changed). Merge findings before presenting.

If an agent fails twice on the same task or two agents produce conflicting recommendations, present both perspectives to the user — do not silently pick one.

If a task needs a capability not covered by existing agents, suggest creating one with `/new-agent`.
