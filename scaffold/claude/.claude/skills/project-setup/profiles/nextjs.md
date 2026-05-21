## Next.js + React Conventions

### Component Rules
- Server Components by default — `'use client'` only for interactivity, real-time updates, or browser APIs
- One component per file — file name matches component name in PascalCase
- Props typed with an inline `interface Props` at the top of the file
- No prop drilling beyond 2 levels — use context, Zustand, or server-side state

### Naming
- Components and pages: `PascalCase`
- Hooks: `useCamelCase`
- Utilities and helpers: `camelCase`
- Files: `kebab-case` (except components which match their export name)
- Route directories: `kebab-case` inside `app/`

### App Router Patterns
- `page.tsx` for routes, `layout.tsx` for shared layouts, `loading.tsx` for streaming
- `error.tsx` for error boundaries at the route level
- Server actions in dedicated `actions/` files with `"use server"` at the top
- Data fetching in Server Components — not in `useEffect`
- `generateMetadata` for every public page

### Client Components
- EventSource / WebSocket connections must clean up on unmount
- `useCallback` and `useMemo` for computationally expensive values — not by default
- Forms use controlled inputs or React Hook Form — no uncontrolled

### Commands
- Dev: `npm run dev`
- Build: `npm run build`
- Test: `npm test` (Vitest or Jest with jsdom)
- Lint: `npm run lint`
- Type check: `tsc --noEmit`

### Security
- Validate all route params and search params with Zod in Server Components
- Never expose internal error messages to the client
- Server actions validate inputs — never trust client-side data
- `next/headers` for reading cookies server-side — never `document.cookie`
