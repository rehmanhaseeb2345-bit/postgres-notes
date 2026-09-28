<div align="center">

# 30 · Managing Database Design with Schema Migrations

**Part 6 — Transactions & Migrations** · ✅ Done

</div>

> Every schema change in this entire course happened by re-running `DROP TABLE` + `CREATE TABLE` from a fresh `.sql` file. That's fine for a learning database with disposable seed data — it would delete every real row in a production database with actual users. Migrations are how schema changes happen on data that has to survive them.

💾 This section is about process and tooling more than new SQL syntax — [`examples.sql`](examples.sql) has the illustrative pieces.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [The problem migrations solve](#1-the-problem-migrations-solve) | Changing a live schema without destroying live data |
| 2 | [Up and down migrations](#2-up-and-down-migrations) | Every change, paired with its exact reverse |
| 3 | [Migration tools live outside Postgres](#3-migration-tools-live-outside-postgres) | Postgres has no built-in concept of "a migration" |
| 4 | [Writing and running migrations](#4-writing-and-running-migrations) | Numbered files, run in order, tracked in a table |
| 5 | [Reverting migrations](#5-reverting-migrations) | Undoing changes, in reverse order |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. The problem migrations solve

**What it is:** A way to change a schema **incrementally**, on a database that already has real rows in it — instead of dropping and recreating tables from scratch.

**Why it exists:** Section 13's `DROP TABLE IF EXISTS products; CREATE TABLE products (...)` pattern, used throughout this course, is completely fine when `products` only ever has disposable seed data. On a real, live `products` table with real inventory, real orders referencing it, real history — dropping it isn't a schema change, it's data loss.

### The actual constraint

Every schema change on a live database has to be expressed as **incremental** statements — `ALTER TABLE ... ADD COLUMN`, `ALTER TABLE ... ADD CONSTRAINT` (both from section 13) — applied to the table *as it currently exists*, never a fresh rebuild.

---

## 2. Up and down migrations

**What it is:** Every migration is written as **two** directions: an "up" (apply the change) and a "down" (the exact reverse) — so any change made can also be un-made.

**Why it exists:** A change that can't be undone is a much bigger risk to ship. "Add this constraint" needs a matching "remove this constraint" defined *before* it's ever needed in a hurry, not improvised after something goes wrong.

### Example — formalizing section 13's constraint addition

**Up:**
```sql
ALTER TABLE products ADD CONSTRAINT stock_non_negative CHECK (stock >= 0);
```

**Down:**
```sql
ALTER TABLE products DROP CONSTRAINT stock_non_negative;
```

### Example — adding a column

**Up:**
```sql
ALTER TABLE photos ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT NOW();
```

**Down:**
```sql
ALTER TABLE photos DROP COLUMN updated_at;
```

### ⚠️ Traps

- **A "down" migration that can't actually restore the previous state.** Dropping a column is a perfect reverse of adding one *only if* nothing has written meaningful data into it yet. `DROP COLUMN updated_at` after real data has accumulated in it is a real, permanent data loss — "down" undoes the *schema* change; it doesn't necessarily undo everything that happened because of it.

---

## 3. Migration tools live outside Postgres

**What it is:** Postgres itself has no built-in concept of "a migration" — `ALTER TABLE` is just SQL. The numbering, the tracking of what's already been applied, the up/down pairing — all of that comes from a separate tool: Flyway, Alembic, Django's migrations, Rails' `ActiveRecord`, Knex, Prisma Migrate, and others.

**Why it exists:** Someone has to remember *which* migrations have already run against *this* database, so the same `ADD COLUMN` doesn't get applied twice (which would just error) and so every team member's database ends up in the same state.

### How they all actually work, underneath

Every one of these tools, regardless of language or ecosystem, does the same three things:

1. Keeps a table (inside the very Postgres database being migrated) recording which migrations have already run.
2. Compares that table against the migration files on disk to find what's pending.
3. Runs the pending ones, in order, each inside a transaction (section 29) — so a failed migration doesn't leave the schema half-changed.

### ⚠️ Traps

- **Running a migration's SQL by hand instead of through the tool "just this once."** The tool's tracking table doesn't know it happened — the next real migration run will try to apply it again, and (topic 4) that second attempt usually just errors, or worse, silently succeeds and diverges from what the tool believes is true.

---

## 4. Writing and running migrations

**What it is:** One file (or file pair) per change, named so their order is unambiguous — usually a timestamp or sequential number prefix.

**Why it exists:** Migrations have to run in a specific order; a naming scheme that sorts correctly *is* that order.

### A minimal version of the mechanism, in plain SQL

```sql
CREATE TABLE schema_migrations (
    version    VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

Applying migration `002_add_photos_updated_at` looks like this, wrapped in a transaction so a failure can't leave `products` half-changed with no record of it:

```sql
BEGIN;
ALTER TABLE photos ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT NOW();
INSERT INTO schema_migrations (version) VALUES ('002_add_photos_updated_at');
COMMIT;
```

Real tools automate exactly this: check `schema_migrations` for what's missing, run each missing file's SQL, record it, one transaction per migration.

### File naming, illustrated

```
migrations/
├── 001_add_stock_non_negative.up.sql
├── 001_add_stock_non_negative.down.sql
├── 002_add_photos_updated_at.up.sql
├── 002_add_photos_updated_at.down.sql
```

### ⚠️ Traps

- **Editing an already-applied migration file instead of writing a new one.** Anyone who already ran the old version has a `schema_migrations` row saying it's done — editing the file changes nothing for them. A schema fix always needs its own new migration, never a rewrite of history.

---

## 5. Reverting migrations

**What it is:** Running a migration's "down" — and, for more than one, running them in the **reverse** of the order they were applied.

**Why it exists:** Migration `002` might depend on something `001` set up. Reverting `001` before `002` could try to undo a foundation something later still depends on.

### Example

```sql
BEGIN;
ALTER TABLE photos DROP COLUMN updated_at;
DELETE FROM schema_migrations WHERE version = '002_add_photos_updated_at';
COMMIT;
```

### ⚠️ Traps

- **Reverting in the order they were applied, instead of backward.** Undoing `001` (which `002` might reference or assume) before undoing `002` risks the "down" migration itself failing, or worse, succeeding while leaving the schema in a state no migration file actually describes.

---

## Recap

| Concept | What it means |
|---|---|
| Migration | An incremental, trackable schema change — not a rebuild |
| Up / down | Every change paired with its exact reverse |
| Migration tool | Tracks what's applied, runs what's pending, in order — lives outside Postgres itself |
| `schema_migrations` table | The actual mechanism every tool is built on |
| Reverting | Down migrations, run in reverse order of how they were applied |

> **The one thing I want to remember:** this entire course's `DROP TABLE; CREATE TABLE;` habit was only ever safe because the data was disposable. The instant real data exists, every schema change has to be an incremental, reversible step — which is the entire reason migrations exist as their own discipline.

---

## Practice

**1.** Write the up and down migration for adding a `bio_updated_at TIMESTAMPTZ` column to `user_profiles`.

<details>
<summary>Show answer</summary>

**Up:**
```sql
ALTER TABLE user_profiles ADD COLUMN bio_updated_at TIMESTAMPTZ;
```
**Down:**
```sql
ALTER TABLE user_profiles DROP COLUMN bio_updated_at;
```

</details>

**2.** Migration `003` adds a `NOT NULL` constraint to a column that migration `002` created. Which order should they be *reverted* in, and why?

<details>
<summary>Show answer</summary>

**`003` first, then `002`.** `003`'s constraint depends on `002`'s column already existing — reverting `002` (dropping the column) first would either fail outright or leave `003`'s down migration trying to drop a constraint on a column that's already gone.

</details>

**3.** Why does wrapping a migration in `BEGIN`/`COMMIT` (topic 4) matter specifically for the two-statement pattern (schema change + `INSERT INTO schema_migrations`)?

<details>
<summary>Show answer</summary>

Without a transaction, the schema change could succeed while the tracking insert fails (or the reverse) — leaving the real schema and the tool's record of it disagreeing. Section 29's atomicity is exactly what keeps "the change happened" and "we recorded that it happened" as a single, indivisible fact.

</details>

---

## What confused me

- I didn't expect Postgres to have *zero* built-in concept of a migration. Every piece — file numbering, the tracking table, up/down pairing — turned out to be convention and tooling built entirely on top of plain `ALTER TABLE` and a regular table, not a Postgres feature at all.
- "Down" migrations felt redundant at first — why write the undo before ever needing it? Realizing a rushed, improvised rollback under pressure is a much worse time to be figuring out the exact reverse of a schema change is what made writing it upfront make sense.
- I assumed reverting migrations in the same order they were applied would be fine, the same way I'd undo a stack of edits. It's actually backward from that — later migrations often depend on earlier ones, so undoing has to go in reverse, most-recent-first.

---

[⬅ 29 · Handling Concurrency and Reversibility with Transactions](../29-handling-concurrency-and-reversibility-with-transactions/README.md) · [🏠 Index](../README.md) · [31 · Schema vs Data Migrations ➡](../31-schema-vs-data-migrations/README.md)
