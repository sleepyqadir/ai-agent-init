## TypeScript + Node.js Conventions

### Naming
- Variables and functions: `camelCase`
- Classes, interfaces, types, enums: `PascalCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Files and directories: `kebab-case`
- Database columns: `snake_case`

### Types
- All type definitions in `src/types/` or colocated with the module
- No `any` — use `unknown` with type guards, or a specific type
- Prefer `interface` for object shapes, `type` for unions and computed types
- Exported types have JSDoc only if the name isn't self-explanatory

### Imports
- Use path aliases (`@/` prefix for src root)
- Group: external packages → `@/` internal → relative → types
- Blank line between groups

### Async
- `async/await` for all I/O — never callbacks, never mixing with `.then()`
- Typed errors — custom error classes, not `throw new Error("string")`
- Unhandled promise rejections are bugs, not warnings

### Commands
- Build: `npm run build` or `tsc`
- Test: `npm test` (Vitest preferred, Jest acceptable)
- Lint: `npm run lint` (ESLint + Prettier)
- Type check: `tsc --noEmit`

### Security
- Validate request bodies with Zod at every API boundary
- Use `helmet` for HTTP security headers
- Parameterized queries via an ORM or tagged template literals — never string concatenation
- `npm audit` on every dependency change
