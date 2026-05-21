## Performance and Context

**Model selection (current defaults):**
- Haiku: quick lookups, simple generation, summarization, formatting
- Sonnet: standard development — writing code, reviewing, debugging
- Opus: architecture decisions, complex multi-step reasoning, critical security review

**Context management:**
- Use subagents to protect the main context. Each agent gets a fresh window.
- The main conversation holds summaries, not raw output from agent work.
- Glob and Grep before Read for large or unknown files. Read small, directly relevant files fully when complete context prevents mistakes.
- When context grows long, summarize completed work and reset focus to remaining tasks.
- Never load large files unnecessarily. Read only the sections relevant to the task.
- Keep the active working set to 5–7 files. Release files from focus when no longer being edited.

**Tool use:**
- Make independent tool calls in parallel. Reading 3 files? Read them simultaneously.
- Only call tools you need. Unnecessary reads burn context and tokens.
