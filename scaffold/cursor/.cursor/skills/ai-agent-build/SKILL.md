---
name: ai-agent-build
description: Build AI agents, LLM pipelines, or multi-agent systems with eval-first methodology covering orchestration, cost, and reliability.
---

# AI Agent Build

Define what success looks like before writing any code. Then build. Then measure.

## Phase 1: Define the Problem

Answer these before touching code:
- What specific task does this agent solve?
- What does the input look like? (format, size, source)
- What does good output look like? (concrete examples)
- What does bad output look like? (failure modes)
- What's the acceptable latency? (200ms? 5s? 30s?)
- What's the acceptable cost per run?

## Phase 2: Design the Evaluation

**Before building — define your eval:**

```
Eval name: [descriptive name]
Inputs:    [N examples in src/evals/inputs/]
Expected:  [N expected outputs in src/evals/expected/]
Method:    [LLM-as-judge | exact-match | human | custom scorer]
Threshold: [N% pass rate]
Runs in:   [CI | staging | manual]
```

Minimum: 10 examples. Target: 50. These are your ground truth.

Write the eval runner before building the agent. This forces clarity on what "correct" means.

## Phase 3: Design the Architecture

Use a `generalPurpose` Task subagent for complex AI system architecture. Provide:
- The problem definition from Phase 1
- The eval definition from Phase 2
- Existing infrastructure and constraints

The architecture output must include:

**Orchestration pattern** — choose one:
- **Sequential pipeline**: A → B → C → output. Use when each step depends on the previous.
- **Fan-out / fan-in**: parallel agents merged at the end. Use when sub-tasks are independent.
- **Supervisor**: orchestrator directs specialists dynamically. Use when workflow isn't known upfront.
- **Handoff chain**: backend builds, frontend consumes via API summary contract.

**For each agent, define:**
- Role (one clear job description)
- Model (cheapest that meets quality bar)
- Tools (least privilege — only what it actually needs)
- Input format (exactly what context it receives)
- Output format / schema (exactly what it must return)
- Failure behavior (what happens when it fails or returns bad output)

**Cost estimate:**
- Agents involved and their models
- Estimated input tokens per agent
- Estimated output tokens per agent
- Total cost per pipeline run
- Cost at scale (per 1000 runs)
- Flag pipelines that will cost more than $0.10/run

**Reliability design:**
- Every LLM call: 30s timeout default, 3 retries with exponential backoff
- Structured output (JSON schema or tool use) — never parse free text for critical paths
- Fallback behavior when a model call fails
- Context window budget per agent

Present the design. Wait for approval.

## Phase 4: Build the Foundation

Before building agents, build the infrastructure:
- Retry wrapper with exponential backoff
- Structured output parser with error handling
- Token usage logger
- Cost estimator (input tokens × model price + output tokens × model price)

These are reusable across all agents in the project.

## Phase 5: Build Agents

For each agent, implement in this order:
1. Define the system prompt in `src/prompts/[name]-system.md`
2. Define the output schema (JSON Schema or Zod/Pydantic)
3. Implement the agent function
4. Write a unit test against the eval golden set

**Prompt injection defense** (for any agent processing user content):
- Separate instruction prompts from data prompts
- Wrap user/external content in clear delimiters (`<user_input>...</user_input>`)
- Strip or escape XML/HTML-like tags from user input
- Never give an agent processing untrusted input access to destructive tools without human confirmation
- Include adversarial inputs in eval suite: "Ignore previous instructions...", multi-language injection

## Phase 6: Build Orchestration

Implement the pipeline that connects agents:
- Wire inputs and outputs between agents
- Apply the retry and timeout infrastructure
- Add token usage logging at each step
- Test the full pipeline end-to-end with 3–5 real inputs

## Phase 7: Run Evals

```bash
# Run the eval suite
[EVAL_COMMAND]

# Expected output:
# Pass: N/N examples (N%)
# Cost per run: $N
# P50 latency: Ns
```

If pass rate is below threshold: investigate failures before shipping.

## Phase 8: Reliability Check

- What happens when the LLM returns malformed JSON?
- What happens when the API returns a 429 or 500?
- What happens when the context window is exceeded?
- Is there a circuit breaker for high-volume pipelines?

Document the answers. Implement the handlers.

**Observability schema** — log for every AI pipeline run:
```json
{
  "trace_id": "unique per call",
  "pipeline_id": "links multi-agent traces",
  "model": "model used",
  "prompt_version": "version identifier",
  "input_tokens": 0,
  "output_tokens": 0,
  "latency_ms": 0,
  "status": "success | retry | fallback | error",
  "validation_result": "pass | fail | skipped",
  "cost_usd": 0.00
}
```

## Rules
- NEVER build before defining the eval. "We'll add evals later" means never.
- NEVER use `any` or untyped parsing for LLM output in production code
- NEVER hardcode model names — use config constants
- Every agent has one job. Split agents that do multiple things.
- Cost estimate before every multi-agent pipeline — no surprises at scale
- Fallback paths must be tested. An untested fallback is no fallback at all.
