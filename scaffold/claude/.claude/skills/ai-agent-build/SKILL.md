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

Delegate to `ai-architect` agent for complex systems. For simpler cases:

- Choose the orchestration pattern (sequential / fan-out / supervisor / handoff)
- Define each agent: role, model, tools, input format, output format, failure behavior
- Draw the data flow (text diagram is fine)
- Estimate cost per run

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

## Rules
- NEVER build before defining the eval. "We'll add evals later" means never.
- NEVER use `any` or untyped parsing for LLM output in production code
- NEVER hardcode model names — use config constants
- Every agent has one job. Split agents that do multiple things.
- Cost estimate before every multi-agent pipeline — no surprises at scale
