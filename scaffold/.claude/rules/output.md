## Output Format

For implementation summaries, use a concise change log:

```
Changed:
- path/to/file — what changed and why

Verification:
- command/result, or "not run" with reason

Risks / follow-ups:
- only if relevant
```

When making architectural changes, flag them explicitly:

```
ARCHITECTURE CHANGE
What changed: [description]
Why: [reasoning and trade-offs]
Impact: [what else is affected and how]
```

Agent reports use structured severity tiers:
- **Critical** — must fix before merge. Blocks the PR.
- **Improvement** — should fix. Not blocking but important.
- **Nitpick** — style or preference. Optional.

All code findings include the exact file path and line number when available; otherwise include the smallest searchable snippet.
All plans include a step list with dependencies and verification methods.

IMPORTANT: Never claim tests, builds, lint, migrations, or scans passed unless they were actually run or the user provided the result.
