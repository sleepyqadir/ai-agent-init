## Rust Conventions

### Naming
- Variables, functions, modules: `snake_case`
- Types, traits, enums: `PascalCase`
- Constants and statics: `SCREAMING_SNAKE_CASE`
- Crate names: `snake_case` (no hyphens in code, hyphens allowed in `Cargo.toml` package name)

### Types
- Prefer owned types in structs; use references (`&str`, `&[T]`) in function parameters
- Use `Result<T, E>` for fallible operations — never `.unwrap()` in production code
- Use `Option<T>` over sentinel values (`-1`, empty string, null pointer)
- Define domain-specific error types with `thiserror`; propagate with `anyhow` in binaries
- Newtype pattern for domain values (`struct UserId(Uuid)`) — prevents accidental mixing

### Structure
```
src/
  main.rs         # Binary entry point (thin — delegates to lib)
  lib.rs          # Library root (public API surface)
  domain/         # Core types, traits, domain logic (no I/O)
  infra/          # Database, HTTP clients, external integrations
  api/            # HTTP handlers (Axum/Actix routes — thin)
  config.rs       # Configuration loaded from environment
tests/            # Integration tests
benches/          # Benchmarks (criterion)
```

### Error Handling
- Use `?` operator consistently — propagate errors up, handle at the boundary
- Match on specific error variants when recovery is possible
- Never use `panic!` in library code; reserve for truly unrecoverable states
- Log errors with context before returning to callers

### Concurrency and Async
- Use `tokio` for async runtimes; `async/await` for all I/O-bound work
- Avoid `Mutex<T>` across `await` points — use `tokio::sync::Mutex` if needed
- Prefer message-passing (`tokio::sync::mpsc`) over shared state
- Mark types `Send + Sync` explicitly when crossing thread boundaries

### Commands
- Build: `cargo build --release`
- Test: `cargo test` (with `cargo test -- --nocapture` for output)
- Lint: `cargo clippy -- -D warnings`
- Format: `cargo fmt --check`
- Audit: `cargo audit`
- Coverage: `cargo llvm-cov`

### Security
- Validate all external input at the boundary — use `validator` crate for struct-level validation
- Parameterized queries via `sqlx` with compile-time checked queries — never string interpolation into SQL
- Secrets from environment via `dotenvy` + `std::env::var` — never hardcoded defaults
- Run `cargo audit` on every `Cargo.lock` change
- Enable `deny(unsafe_code)` in library crates unless FFI is explicitly required
- Use `zeroize` for sensitive data (passwords, keys) to clear memory on drop
