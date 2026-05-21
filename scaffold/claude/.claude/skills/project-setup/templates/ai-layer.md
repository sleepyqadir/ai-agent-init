## AI Patterns

This project involves LLMs or AI agents. These rules apply in addition to the standard rules.

### Model Selection
Define your cost/quality tiers and document them here:
- **Fast/cheap tier** (e.g. Haiku): [use cases]
- **Standard tier** (e.g. Sonnet): [use cases]
- **High-quality tier** (e.g. Opus): [use cases]

Never hardcode model names in business logic. Use a config constant or environment variable.

### Evaluation First
Define how you measure output quality BEFORE building any AI feature:
- Golden set: [where stored, how many examples]
- Evaluation method: [LLM-as-judge | exact match | human eval | custom scorer]
- Pass threshold: [N%]
- Eval runs in CI: [yes/no]

### Context Window Budget
Document the expected context budget for each major workflow:
- [Workflow name]: [estimated tokens in / tokens out]
- Never exceed 70% of context window without compacting or summarizing

### Cost Targets
- Estimated cost per request: $[N]
- Daily budget at expected volume: $[N]
- Alert threshold: $[N]

### Reliability Contract
- LLM call timeout: [N seconds]
- Retry strategy: [N retries, exponential backoff]
- Fallback behavior: [what happens when a model call fails]
- Structured output: use JSON schema or tool use — never parse free text for critical paths

### Prompt Versioning
Prompts are code. Version them:
- System prompts live in `[location]`
- Prompt changes go through code review
- Breaking prompt changes require an eval run before merge
