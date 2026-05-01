## Output Format

When creating or modifying a file, lead with a structured header:

```
[filepath]
Purpose: [one-line description]
Depends on: [imports/dependencies this file needs]
Exposes: [what this file exports or provides]
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

All code findings include the exact file path and line number.
All plans include a step list with dependencies and verification methods.
