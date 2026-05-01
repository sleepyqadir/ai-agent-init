## AI Patterns (active when project involves LLMs or AI agents)

**Model selection:**
- Define a cost/quality decision tree at project start. Document it in CLAUDE.md.
- Default to the cheapest model that meets quality requirements. Escalate explicitly.
- Never hardcode model names in business logic. Use a config constant or environment variable.

**Prompt hygiene:**
- Treat prompts as code. Version them, review them, test them.
- Separate system prompt from user content. Never concatenate user input directly into system prompts.
- Test prompts with adversarial inputs before shipping. Users will try to break them.

**Context windows:**
- Never exceed 70% of a model's context window without compacting or summarizing.
- Long-running agent sessions need explicit context management — summarize completed work, discard irrelevant history.
- Document the expected context budget in CLAUDE.md for each major workflow.

**Evaluation-first:**
- Define how you will measure output quality BEFORE building the feature.
- Every AI feature needs at minimum: a set of golden examples and a pass/fail threshold.
- Evals run in CI. A regression in eval score blocks merge.

**Cost awareness:**
- Estimate token cost before running multi-agent pipelines in production.
- Log token usage per request. Set budget alerts.
- Cache LLM responses where the input is deterministic and latency tolerance allows.

**Reliability:**
- Every LLM call needs a timeout and a retry strategy with exponential backoff.
- Define fallback behavior when a model call fails or returns malformed output.
- Structured output (JSON schema or tool use) is more reliable than parsing free text.
