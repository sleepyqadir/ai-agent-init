## Python + FastAPI Conventions

### Naming
- Variables, functions, modules: `snake_case`
- Classes: `PascalCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private members: `_single_underscore`
- Files and directories: `snake_case`

### Types
- All functions have type annotations — parameters and return types
- Pydantic models for request/response schemas — never raw dicts at API boundaries
- `Optional[T]` or `T | None` for nullable values
- No bare `except:` — always catch specific exceptions

### Structure
```
app/
  api/          # Route handlers (thin — delegate to services)
  services/     # Business logic
  models/       # SQLAlchemy models or Pydantic schemas
  repositories/ # Database access layer
  core/         # Config, dependencies, middleware
  tests/        # Mirrors app/ structure
```

### Async
- `async def` for all route handlers and I/O-bound operations
- `await` correctly — never call `await` on sync functions
- Background tasks via `BackgroundTasks` or a task queue (Celery, ARQ) — not bare threads

### Commands
- Dev: `uvicorn app.main:app --reload`
- Test: `pytest` (with `pytest-asyncio` for async tests)
- Lint: `ruff check .`
- Format: `ruff format .`
- Type check: `mypy .`

### Security
- Validate all inputs with Pydantic — FastAPI handles this automatically for typed endpoints
- Parameterized queries via SQLAlchemy ORM — never `text()` with user input
- Secrets via `pydantic-settings` from environment — never `os.environ.get()` with defaults for secrets
- `pip audit` on every dependency change
- Rate limiting via `slowapi` on public endpoints
