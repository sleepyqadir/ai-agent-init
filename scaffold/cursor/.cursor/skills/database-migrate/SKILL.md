---
name: database-migrate
description: Create and safely apply database migrations with rollback SQL generated before every run.
---

# Database Migration

Never run a migration without understanding what it does and how to undo it.

## Phase 1: Write or Review the Migration

If creating:
- One migration = one logical change
- Name it clearly: `add_user_email_index`, `drop_legacy_tokens_table`, `add_status_to_orders`
- Include both up and down directions if your framework supports it

If reviewing an existing file:
- Read the full migration before proceeding

## Phase 2: Classify Operations

Go through each operation and classify it:

**Safe — no special handling:**
- CREATE TABLE
- ADD COLUMN (nullable, with default)
- CREATE INDEX CONCURRENTLY (Postgres)
- ADD FOREIGN KEY ... NOT VALID (Postgres)

**Requires care — assess table size first:**
- ADD COLUMN NOT NULL without default → blocks writes on large tables
- ADD UNIQUE CONSTRAINT → full table scan
- ADD INDEX (non-concurrent) → locks table

**Dangerous — requires explicit confirmation:**
- DROP TABLE
- DROP COLUMN
- TRUNCATE
- Changing column type
- Removing NOT NULL

## Phase 3: Schema Review

For new or changed schemas, verify:
- **Normalization** — Is data duplicated across tables? Should it be extracted?
- **Constraints** — Are NOT NULL, UNIQUE, and FOREIGN KEY constraints appropriate?
- **Indexes** — Are foreign keys indexed? Are columns used in WHERE/JOIN/ORDER BY indexed?
- **Naming** — Are table and column names consistent (snake_case), clear, and non-ambiguous?
- **Types** — Are column types appropriate? (`varchar(255)` vs `text`, `int` vs `bigint` for IDs)
- **Soft deletes** — If used, is there an index on `deleted_at`?
- **N+1 risks** — Are queries inside loops? Use JOIN or batch loading instead.
- **SELECT *** — Never in production queries. List columns explicitly.
- **Missing LIMIT** — User-facing list queries must have a LIMIT.

For complex schema design changes, use a `generalPurpose` Task subagent with the migration file and request a full database safety review.

## Phase 4: Pre-Flight Checks

```bash
# Check if there are uncommitted changes to migration files
git status --short | grep migration

# Validate syntax (framework-specific)
# Prisma:   npx prisma validate
# Drizzle:  npx drizzle-kit check
# Alembic:  alembic check
# Flyway:   flyway validate

# Check for the backup (for dangerous ops)
# Confirm with user: "Is there a recent backup?"
```

## Phase 5: Generate Rollback SQL

Before running, produce the SQL that would undo this migration:

```sql
-- Rollback for: [migration name]
-- Generated: [date]

-- If ADD COLUMN:         ALTER TABLE [t] DROP COLUMN [c];
-- If CREATE TABLE:       DROP TABLE [t];
-- If ADD INDEX:          DROP INDEX [name];
-- If DROP TABLE:         [Cannot auto-generate — requires restore from backup]
```

For DROP operations: state clearly that rollback requires a backup restore.

## Phase 6: Run

```bash
# Dry run first if supported:
# Prisma:   npx prisma migrate dev --create-only
# Alembic:  alembic upgrade head --sql
# Flyway:   flyway migrate -dryRunOutput=dry-run.sql

# Then apply:
# Prisma:   npx prisma migrate deploy
# Alembic:  alembic upgrade head
# Django:   python manage.py migrate
# Knex:     npx knex migrate:latest
```

## Phase 7: Verify

```bash
# Check migration ran successfully
# Check the schema reflects the expected change
# Run the test suite to catch any breakage
```

## Rules
- Never run a destructive migration without confirming a backup exists
- Always generate rollback SQL before running
- Dangerous operations require explicit user confirmation before proceeding
- N+1 in production is a silent killer. Flag every instance.
- `SELECT *` in production code is always a finding.
