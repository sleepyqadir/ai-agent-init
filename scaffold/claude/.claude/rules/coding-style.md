## Coding Style

- Follow existing project conventions when they conflict with these rules, unless the convention is unsafe or the user explicitly asks to change it.
- Prefer immutability. Use `const`, `readonly`, frozen structures. Mutate only when performance demands it.
- Keep files focused. If a file grows beyond ~800 lines, consider splitting at logical boundaries.
- Keep functions small. If a function exceeds ~50 lines, consider extracting named helpers.
- Avoid nesting deeper than 3 levels. Use early returns and guard clauses to flatten logic.
- Name things to eliminate the need for comments. `getUserById` not `getUser`. `isEmailVerified` not `check`.
- One primary export per file. Utility files may export multiple small helpers.
- No dead code. Delete it. Version control is your undo history.
- Avoid barrel re-export files (`index.ts`) unless the module has a deliberate public API boundary.
- Composition over inheritance. Small composable functions over class hierarchies.
- Avoid premature abstraction. Wait for repeated, stable patterns before extracting. Three similar lines is better than a wrong abstraction.
- Public functions and interfaces should have explicit return types where the language supports them.
- Replace unexplained magic numbers and strings with named constants.
- Group imports: external dependencies → internal modules → types. Blank line between groups.
