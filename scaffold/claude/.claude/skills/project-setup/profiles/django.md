## Django Conventions

### Naming
- Variables, functions, modules: `snake_case`
- Classes (models, views, forms, serializers): `PascalCase`
- Constants: `SCREAMING_SNAKE_CASE`
- URL names: `kebab-case` (e.g. `user-detail`)
- Template names: `snake_case.html` in `<app>/templates/<app>/`

### Types
- All functions have type annotations (use `mypy` to enforce)
- Use `Optional[T]` or `T | None` for nullable values (Python 3.10+)
- DRF serializers or Pydantic models at API boundaries — never raw `request.data`
- No bare `except:` — always catch specific exceptions

### Structure
```
project/
  settings/
    base.py       # Shared settings
    local.py      # Dev overrides
    production.py # Prod overrides (no secrets — reads from env)
  urls.py         # Root URL conf
  wsgi.py
<app>/
  models.py       # Django ORM models
  views.py        # Views / viewsets (thin — delegate to services)
  serializers.py  # DRF serializers
  services.py     # Business logic (no HTTP, no ORM — pure Python)
  urls.py         # App-level URL conf
  admin.py        # Admin registration
  tests/
    test_models.py
    test_views.py
    test_services.py
```

### ORM and Database
- Migrations are one-way forward — never edit existing migration files
- Use `select_related` / `prefetch_related` to avoid N+1 queries
- Raw SQL only via `connection.execute()` with parameterized queries — never f-strings into SQL
- Transactions via `@transaction.atomic` or `with transaction.atomic()`
- Index fields used in `filter()`, `order_by()`, and foreign keys

### Commands
- Dev: `python manage.py runserver`
- Migrations: `python manage.py makemigrations && python manage.py migrate`
- Test: `pytest` with `pytest-django` (not `manage.py test`)
- Lint: `ruff check .`
- Format: `ruff format .`
- Type check: `mypy .`
- Audit: `pip-audit`

### Security
- `DEBUG=False` in production — enforced via environment variable, never hardcoded
- `SECRET_KEY` from environment — never committed or defaulted to a weak value
- `ALLOWED_HOSTS` explicitly set from environment — never `['*']` in production
- Use Django's built-in CSRF protection — never disable with `@csrf_exempt` on write endpoints
- ORM parameterizes queries automatically — use ORM; avoid `.extra()` with user input
- `pip-audit` on every `requirements*.txt` or `pyproject.toml` change
- Rate-limit authentication endpoints with `django-ratelimit` or middleware
- Store passwords with `bcrypt` backend: `PASSWORD_HASHERS = ['django.contrib.auth.hashers.BCryptSHA256PasswordHasher', ...]`
