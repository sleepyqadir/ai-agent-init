## AI Project Profile

Use this profile when the project involves LLMs, AI agents, or intelligent pipelines — regardless of the underlying language stack. Apply this on top of the language-specific profile.

### Project Structure
```
src/
  agents/         # Agent definitions and orchestration
  prompts/        # System prompts and prompt templates (versioned)
  evals/          # Evaluation datasets and runners
  pipelines/      # Multi-step AI workflows
  tools/          # Tool definitions for agents
  config/         # Model configs, cost tiers
```

### Model Configuration
```
# Never hardcode. Always from config:
MODEL_FAST=       # e.g. claude-haiku-4-5  (search, classification, simple tasks)
MODEL_STANDARD=   # e.g. claude-sonnet-4-6 (standard dev tasks, generation)
MODEL_QUALITY=    # e.g. claude-opus-4-7   (architecture, critical review)
```

### Prompt Conventions
- System prompts in `src/prompts/` as `.md` or `.txt` files — never inline strings in code
- Prompt files named: `[agent-name]-system.md`, `[workflow-name]-user.md`
- User content is never concatenated into system prompts
- Prompt changes reviewed like code changes — diff is meaningful

### Eval Conventions
- Evals live in `src/evals/`
- Structure: `inputs/` (test cases), `outputs/` (expected/actual), `runner.py` or `runner.ts`
- Minimum eval set: 20 golden examples per AI feature
- Eval runs on CI: yes — fail the build if score drops below threshold

### Agent Communication
- Agents communicate via structured outputs (JSON schema or tool use)
- Agent contracts defined in `src/agents/[name].ts` or `src/agents/[name].py`
- Handoffs documented: what data format flows between agents

### Cost Tracking
- Every LLM call logs: model, input tokens, output tokens, latency
- Log structured: `{ model, inputTokens, outputTokens, latencyMs, pipeline, step }`
- Token usage visible in dashboards before costs become surprises

### Reliability
- All LLM calls wrapped in retry utility with exponential backoff
- Timeout per call configured — not system default
- Structured output parsing has explicit error handling for malformed responses
- Circuit breaker pattern for high-volume pipelines
