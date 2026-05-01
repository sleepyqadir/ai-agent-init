## Ops and Production Safety

- All configuration in environment variables. Never hardcode URLs, ports, or credentials — even for dev.
- Database migrations are one-way forward. Never modify existing migration files. Add new ones.
- Before any destructive database operation (DROP, DELETE, TRUNCATE): confirm a backup exists.
- New environment variables must be documented in `.env.example` immediately when added.
- Never deploy with failing tests, failing builds, or lint errors.
- Feature flags over long-lived branches. Merge often, hide behind flags.
- Rollback plan is required before any breaking change goes to production.
- Health check endpoints must return non-200 if the service is degraded, not just if it crashes.
- Log at the right level: DEBUG for development noise, INFO for important state changes, ERROR for failures that need attention.
- Connection pools have explicit size limits. Never create unbounded connections.
