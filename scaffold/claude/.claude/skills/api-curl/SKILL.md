---
name: api-curl
description: >-
  Generate ready-to-run curl commands for API endpoints.
  Triggers: curl, generate curl, api curl, test endpoint, http request, api request
  Produces: copy-paste curl commands with auth, headers, and body.
---

# API Curl Generator

Generate accurate, copy-paste curl commands for any API endpoint in the project.

## Phase 1: Discover the API

Before generating anything:
1. Find route/endpoint definitions — check for:
   - Express/Fastify/Hono routes (`app.get`, `router.post`, etc.)
   - Next.js API routes (`app/api/`, `pages/api/`)
   - Django/Flask/FastAPI endpoints
   - OpenAPI/Swagger spec files (`openapi.yaml`, `swagger.json`)
   - Any `routes/`, `controllers/`, or `handlers/` directories
2. Identify the base URL pattern — check `CLAUDE.md`, `.env.example`, `docker-compose.yml`, or config files for the dev server URL/port
3. If the user specified an endpoint, locate its handler directly

## Phase 2: Extract Endpoint Details

For each endpoint, gather:
- **Method**: GET, POST, PUT, PATCH, DELETE
- **Path**: including path parameters (`:id`, `{id}`, `[id]`)
- **Auth**: Bearer token, API key header, cookie, basic auth — check middleware/guards
- **Headers**: Content-Type, Accept, custom headers required
- **Query params**: optional and required
- **Request body**: shape, required fields, types
- **Response**: expected status code and shape (for verification)

## Phase 3: Generate the Curl Command

Format each curl command following these conventions:

### Single-line (simple GET):
```bash
curl -s http://localhost:3000/api/users/123 -H "Authorization: Bearer $TOKEN"
```

### Multi-line (complex requests):
```bash
curl -s -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "email": "user@example.com",
    "name": "Jane Doe",
    "role": "admin"
  }'
```

### Conventions:
- Use `-s` (silent) to suppress progress bars
- Use `-X METHOD` only when not GET (curl defaults to GET)
- Use `$TOKEN` / `$API_KEY` environment variable placeholders for secrets — never hardcode
- Use `localhost` with the project's actual dev port
- Use realistic but obviously fake sample data (`user@example.com`, not `test@test.com`)
- Include `-w "\n%{http_code}\n"` variant as a comment for debugging
- For file uploads: use `-F "file=@path/to/file"`
- For form data: use `--data-urlencode`

## Phase 4: Provide Variations

When useful, generate multiple variations:
1. **Happy path** — valid request with all required fields
2. **Auth failure** — missing or invalid token (to verify 401)
3. **Validation error** — missing required field (to verify 400/422)
4. **Not found** — invalid ID (to verify 404)

Group them under clear headings:
```
### Create User (POST /api/users)

# Success (201)
curl ...

# Missing required field (400)
curl ...

# Unauthorized (401)
curl ...
```

## Phase 5: Environment Setup

Provide a setup block at the top if auth is needed:
```bash
# Setup — run once per session
export BASE_URL="http://localhost:3000"
export TOKEN="your-jwt-token-here"

# Get a token (if the project has a login endpoint)
TOKEN=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "dev@example.com", "password": "devpass"}' \
  | jq -r '.token')
```

## Rules

- Never hardcode real secrets, tokens, or credentials in curl commands
- Always use environment variable placeholders (`$TOKEN`, `$API_KEY`)
- Match the project's actual URL structure — don't guess paths
- Include Content-Type header for all requests with a body
- Use `jq` pipes for response parsing only when the user asks or the response needs filtering
- If an OpenAPI spec exists, prefer it as the source of truth over reading handler code
- Generate commands that work on both macOS and Linux (avoid GNU-only flags)
- When the project uses API versioning (`/v1/`, `/v2/`), include the version prefix
