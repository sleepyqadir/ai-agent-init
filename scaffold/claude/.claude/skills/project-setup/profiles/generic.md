## Generic Project Profile

Used when the stack doesn't match a specific profile. These conventions apply to all languages.

### Universal Naming
- Be consistent within the codebase — consistency matters more than which convention you pick
- Public APIs use clear, self-documenting names
- Abbreviations only when universally understood (`id`, `url`, `db`, `api`)

### Universal Structure
- Separate concerns: HTTP handlers, business logic, and data access in different layers
- Configuration isolated from business logic — environment variables, not magic strings
- Tests mirror the source structure

### Universal Commands
Document these in CLAUDE.md immediately after setup:
- `[INSTALL_COMMAND]` — install dependencies
- `[DEV_COMMAND]` — start development server or process
- `[TEST_COMMAND]` — run the test suite
- `[BUILD_COMMAND]` — produce a production artifact
- `[LINT_COMMAND]` — run static analysis

### Universal Security
- No secrets in code. Environment variables only.
- Validate at boundaries. Trust internal code, not external input.
- Dependency audit before every release.
- Parameterized queries. Always.
