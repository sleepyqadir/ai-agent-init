## Go Conventions

### Naming
- Variables, functions, methods: `camelCase` (unexported), `PascalCase` (exported)
- Constants: `PascalCase` (exported), `camelCase` (unexported)
- Acronyms uppercase: `userID`, `apiURL`, `httpClient`
- Files: `snake_case.go`
- Packages: short, lowercase, no underscores (`httputil`, not `http_util`)

### Types
- Use defined types over primitives for domain values (`type UserID string`, not raw `string`)
- Interfaces defined where they're consumed, not where they're implemented
- Prefer small interfaces — single-method interfaces are idiomatic
- Errors are values — return `(T, error)`, never panic in library code

### Structure
```
cmd/
  [binary-name]/   # main package per binary
internal/          # private packages (not importable outside module)
  domain/          # core types and interfaces
  service/         # business logic
  repository/      # database access
  handler/         # HTTP handlers (thin — delegate to services)
pkg/               # reusable packages safe to import externally
```

### Error Handling
- Always handle errors — never `_` an error return
- Wrap errors with context: `fmt.Errorf("creating user: %w", err)`
- Sentinel errors for known cases: `var ErrNotFound = errors.New("not found")`
- Custom error types when callers need to inspect error details

### Concurrency
- Pass context everywhere — first argument to every function that does I/O
- Cancel contexts — never leak goroutines
- Use `errgroup` for concurrent work with error propagation
- Protect shared state with `sync.Mutex` or channels — document which

### Commands
- Build: `go build ./...`
- Test: `go test ./...` (with `-race` flag in CI)
- Lint: `golangci-lint run`
- Format: `gofmt -w .` or `goimports -w .`
- Vet: `go vet ./...`

### Security
- Validate all external input before use
- Parameterized queries via `database/sql` with `?` placeholders — never `fmt.Sprintf` into SQL
- Secrets from environment — never hardcoded, never in `config.go` defaults
- Run `govulncheck ./...` on dependency changes
- `net/http` server must set timeouts: `ReadTimeout`, `WriteTimeout`, `IdleTimeout`
