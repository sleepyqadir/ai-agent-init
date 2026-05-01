## Coding Style

- Prefer immutability. Use `const`, `readonly`, frozen structures. Mutate only when performance demands it.
- Files stay under 800 lines. When approaching the limit, split at logical boundaries — not arbitrary ones.
- Functions stay under 50 lines. If a function needs a comment to explain what it does, it should be two functions.
- Maximum nesting depth: 3 levels. Use early returns and guard clauses to flatten logic.
- Name things to eliminate the need for comments. `getUserById` not `getUser`. `isEmailVerified` not `check`.
- One primary export per file. Utility files may export multiple small helpers.
- No dead code. Delete it. Version control is your undo history.
- No barrel re-export files (`index.ts`) unless the module has a deliberate public API boundary.
- Composition over inheritance. Small composable functions over class hierarchies.
- Group imports: external dependencies → internal modules → types. Blank line between groups.
