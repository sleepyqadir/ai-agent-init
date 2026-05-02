## Ops and Production Safety

- All configuration in environment variables. Never hardcode URLs, ports, or credentials — even for dev.
- Before production or destructive operations, confirm environment, backup, rollback plan, and user approval. Never assume the target environment.
- Database migrations are one-way forward. Never modify existing migration files. Add new ones.
- Schema and API changes should be backward-compatible by default: add new, migrate data, deprecate, then remove. Never remove or rename a column/endpoint in a single deployment.
- Before any destructive database operation (DROP, DELETE, TRUNCATE): confirm a backup exists.
- New environment variables must be documented in `.env.example` immediately when added.
- Never deploy with failing tests, failing builds, or lint errors.
- Feature flags over long-lived branches. Merge often, hide behind flags.
- Rollback plan is required before any breaking change goes to production.
- Services should handle SIGTERM gracefully: stop accepting new work, finish in-flight requests (within a timeout), close connections, exit cleanly.
- Health check endpoints must return non-200 if the service is degraded, not just if it crashes.
- Use structured logs (JSON) with request/job correlation IDs for production flows. Log at the right level: DEBUG for development noise, INFO for important state changes, ERROR for failures that need attention.
- Connection pools have explicit size limits. Never create unbounded connections.
