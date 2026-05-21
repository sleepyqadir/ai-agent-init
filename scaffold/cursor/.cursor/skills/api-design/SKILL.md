---
name: api-design
description: Design API endpoint contracts before any implementation — nothing gets built until the contract is approved.
---

# API Design

Contract first. Code second. Always.

## Phase 1: Use Cases
Before touching any file:
- Who calls this? (browser, mobile app, another service, webhook, cron)
- What decision does the caller make with the response?
- What are the error states the caller must handle?
- Will this endpoint be public, authenticated, or internal-only?

## Phase 2: Audit Existing Patterns
Read 2–3 existing route handlers:
- What does the response envelope look like? (`{ data }` or `{ success, data }` or flat?)
- How are errors returned? (shape, status codes)
- How is auth applied? (middleware, guard, decorator)
- What validation library is used?

## Phase 3: Design the Contract

For each endpoint:

```
[METHOD] /path/:param

Auth:       required | optional | none
Rate limit: [N requests per window]

Request:
  Path:   { param: type }
  Query:  { key: type (optional) }
  Body:   {
    requiredField: type
    optionalField?: type
  }

Response 200:
  {
    field: type   // comment if not obvious
  }

Response 201 (creation):
  { id: uuid, ...created fields }

Response 204 (no content):
  [empty]

Response 400 (validation error):
  { error: "VALIDATION_ERROR", details: { field: string[] } }

Response 401 (unauthorized):
  { error: "UNAUTHORIZED" }

Response 404 (not found):
  { error: "NOT_FOUND", resource: string }

Response 422 (business rule violation):
  { error: "string describing the rule that was violated" }

Response 500:
  { error: "INTERNAL_ERROR" }
```

Use precise types: `string`, `number`, `boolean`, `datetime (ISO 8601)`, `uuid`, `array<T>`, `enum<A|B|C>`.

## Phase 4: Validate the Design

Self-check your contract:
- Consistent naming? (camelCase or snake_case — not mixed)
- Every error has a specific status code and shape?
- Every endpoint has explicit auth requirement?
- No over-fetching? (response contains only what the caller actually uses)
- Breaking changes clearly flagged?

For complex multi-endpoint designs or service integrations, use a `generalPurpose` Task subagent to:
- Review existing API patterns in the codebase
- Validate the contract for consistency with established conventions
- Identify any breaking changes versus current consumers

## Phase 5: Present and Wait

Show the complete contract. Do not start implementation until the user approves.

```
=== API Contract ===

[Contracts as above]

Breaking changes:
  [List, or "none"]

Decisions made:
  [Non-obvious choices and why]

→ Approve to implement, or suggest changes.
```

## Rules
- Zero implementation before approval
- Every endpoint has explicit auth and error documentation
- Breaking changes are always flagged — never introduced silently
- IDOR check required for every data-access endpoint: verify the handler confirms the user owns or has permission for the specific resource
