---
name: daily-update
description: |
  Generate a daily standup "Done" summary from git commits and agent transcripts.
  Triggers: daily update, standup, what did I do today, end of day summary
  Produces: a concise bullet-point list of completed work from the last 24 hours.
---

# Daily Update

Generate a "Done" summary for your daily standup by analyzing git history and agent session context from the last 24 hours.

## Phase 1: Gather Git Commits

Run:
```bash
git log --since="24 hours ago" --oneline --no-merges --author="$(git config user.name)"
```

If no commits found, try without the author filter (solo projects):
```bash
git log --since="24 hours ago" --oneline --no-merges
```

For each non-trivial commit, note:
- The high-level intent (not the file-level detail)
- Group related commits into a single bullet point

## Phase 2: Gather Agent Session Context

Read the agent transcripts from the last 24 hours:
1. List files in the agent-transcripts folder (path provided in system context)
2. Read the parent `.jsonl` files (skip subagent files)
3. Extract the user queries and assistant summaries — these reveal tasks worked on that may not have resulted in commits yet (debugging, research, planning, reviews)

If no transcripts are available or the folder is empty, skip this phase.

## Phase 3: Synthesize the Update

Combine git history and agent context into a single "Done" list following these rules:

**Format:**
```
Done:

- [concise description of completed work item]
- [concise description of completed work item]
- [concise description of completed work item]
```

**Writing rules:**
- Each bullet is one sentence, plain language — no jargon-heavy commit messages
- Group related work into a single bullet (e.g., 5 commits fixing the same feature = 1 bullet)
- Lead with the business outcome, not the technical implementation
- Skip trivial changes (typo fixes, formatting) unless that was the main task
- Maximum 7 bullets — if more, consolidate further
- No "Todo" section — only completed work

**Tone:** Direct, factual, third-person perspective. Match the style:
- Good: "Tier-based subscription system with per-endpoint usage tracking and rate-limit guards"
- Good: "Fix creation timestamp issue in trades"
- Good: "Debug the prompt cache implementation issue"
- Bad: "Worked on various improvements to the subscription module"
- Bad: "Made some fixes and updates to the codebase"

## Phase 4: Present

Output the final update in a clean copy-paste format:

```
Done:

- [item 1]
- [item 2]
- [item 3]
```

No preamble, no explanation, no sign-off. Just the update ready to paste into Slack.

## Rules

- Never fabricate work items — every bullet must trace back to a commit or agent session
- Never include planned or in-progress work — this is strictly "Done"
- If both git and transcripts are empty (no activity in 24h), say so honestly
- Prefer fewer, more meaningful bullets over exhaustive lists
- Skip merge commits, version bumps, and CI-only changes unless they represent real work

## Automated Daily Updates

This skill generates updates interactively inside a session. For automated Slack DMs on a schedule, use the standalone automation:

```bash
# One-time setup (Slack token, user ID, LLM API key, send time)
aiagent-init --setup-daily-update

# Send now (test or manual trigger)
aiagent-init --daily-update

# Disable the schedule
aiagent-init --disable-daily-update
```

The automation works in two phases:
1. **Per-session capture** — the session-close hook automatically saves a structured entry to `.claude/daily-updates.jsonl` at the end of every agent session
2. **Daily send** — at your configured time, the script collects entries from the last 24h, polishes them with an LLM, and DMs you on Slack
