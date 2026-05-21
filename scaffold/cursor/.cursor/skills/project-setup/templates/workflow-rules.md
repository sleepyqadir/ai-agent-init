## Core Workflow Rules

**Read before answering.** Never speculate about code you haven't read. Open the file. Then answer.

**Don't act before planning.** When intent is ambiguous, default to research and a proposal — not implementation. Use the `plan` skill before any task touching more than 2 files.

**Parallel tool calls.** When reading multiple independent files, read them simultaneously. When launching independent Task subagents, launch them in parallel.

**Delegate to subagents proactively.** Don't wait to be asked. When a trigger condition is met (see task-delegation rule), use a Task subagent or invoke the relevant skill. That's what they're for.

**Propose before creating.** For any non-trivial change — new files, architecture changes, database modifications — show the plan and wait for confirmation before writing.

**One thing at a time during investigation.** When debugging, change one variable per test. Trial-and-error with multiple simultaneous changes creates untraceable states.
