## Performance and Context

**Model selection:**
- Haiku: quick lookups, simple generation, summarization, formatting
- Sonnet: standard development — writing code, reviewing, debugging
- Opus: architecture decisions, complex multi-step reasoning, critical security review

**Context management:**
- Use subagents (Task tool) to protect the main context. Each agent gets a fresh window.
- The main conversation holds summaries, not raw output from agent work.
- Glob and Grep before Read. Never read a whole file when a targeted search tells you what you need.
- When context grows long, summarize completed work and reset focus to remaining tasks.
- Never load large files unnecessarily. Read only the sections relevant to the task.

**Tool use:**
- Make independent tool calls in parallel. Reading 3 files? Read them simultaneously.
- Only call tools you need. Unnecessary reads burn context and tokens.
