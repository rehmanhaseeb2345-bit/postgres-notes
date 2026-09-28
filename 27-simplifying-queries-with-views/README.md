<div align="center">

# 27 · Simplifying Queries with Views

**Part 5 — Advanced Querying** · ✅ Done

</div>

> Section 19's capstone query — hashtags, like count, and tag count for every photo — was genuinely useful, and also genuinely long. Retyping it (or copy-pasting it, and forgetting to update one of the copies later) every time I want that information is exactly the problem a view solves.

💾 Every query on this page is in [`examples.sql`](examples.sql). It uses the full `sample-db/` schema.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [What a view is](#1-what-a-view-is) | A saved query, queried like a table |
| 2 | [Creating a view](#2-creating-a-view) | Turning section 19's capstone query into one |
| 3 | [Changing and dropping a view](#3-changing-and-dropping-a-view) | `CREATE OR REPLACE` has real limits |
| 4 | [When to use a view](#4-when-to-use-a-view) | Reuse and clarity — not a performance trick |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. What a view is

**What it is:** A named, saved `SELECT` query that behaves like a table for reading purposes — `SELECT ... FROM view_name` — but re-runs its underlying query **every single time** it's queried. Nothing is cached (that's section 28).

**Why it exists:** A CTE (section 25) names a result for *one* query. A view names it for *every* query, forever, until dropped.

---

## 2. Creating a view

**What it is:** `CREATE VIEW name AS` followed by any ordinary `SELECT`.

**Why it exists:** Section 19's capstone — hashtags, like count, tag count, per photo — is exactly the kind of query worth saving once instead of retyping.

### Syntax

```sql
CREATE VIEW view_name AS SELECT ...;
```

### Example

```sql
CREATE VIEW photo_stats AS
SELECT
    p.id,
    p.url,
    STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hashtags,
    COUNT(DISTINCT l.id)  AS like_count,
    COUNT(DISTINCT pt.id) AS tag_count
FROM photos AS p
LEFT JOIN hashtags_posts AS hp ON p.id = hp.photo_id
LEFT JOIN hashtags AS h        ON hp.hashtag_id = h.id
LEFT JOIN likes AS l           ON l.photo_id = p.id
LEFT JOIN photo_tags AS pt     ON pt.photo_id = p.id
GROUP BY p.id, p.url;
```

Now it's queried exactly like a real table — including adding a fresh `WHERE`, which proves it's genuinely re-running, not returning a saved snapshot:

```sql
SELECT url, like_count FROM photo_stats WHERE like_count > 0 ORDER BY like_count DESC;
```

**Result**

| url | like_count |
|---|--:|
| sunset.jpg | 2 |
| mountain.jpg | 1 |
| city.jpg | 1 |

### ⚠️ Traps

- **Expecting a view to reflect a snapshot from when it was created.** If a new like gets added to `coffee.jpg` after this view exists, querying `photo_stats` again immediately shows it — the underlying query runs fresh every time, using the rewriter stage from section 23's pipeline.

---

## 3. Changing and dropping a view

**What it is:** `CREATE OR REPLACE VIEW` updates a view's definition in place — with one real restriction. `DROP VIEW` removes it entirely.

**Why it exists:** A view might be referenced elsewhere (another view, application code expecting certain columns) — Postgres allows changes that don't break that contract, and blocks ones that would.

### Syntax

```sql
CREATE OR REPLACE VIEW view_name AS SELECT ...;
DROP VIEW view_name;
```

### Example — an allowed change (adding a column)

```sql
CREATE OR REPLACE VIEW photo_stats AS
SELECT
    p.id, p.url,
    STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hashtags,
    COUNT(DISTINCT l.id)  AS like_count,
    COUNT(DISTINCT pt.id) AS tag_count,
    u.username AS owner                 -- new column, added at the end
FROM photos AS p
JOIN users AS u ON p.user_id = u.id
LEFT JOIN hashtags_posts AS hp ON p.id = hp.photo_id
LEFT JOIN hashtags AS h        ON hp.hashtag_id = h.id
LEFT JOIN likes AS l           ON l.photo_id = p.id
LEFT JOIN photo_tags AS pt     ON pt.photo_id = p.id
GROUP BY p.id, p.url, u.username;
```

**Result:** `CREATE VIEW` — succeeds, since the existing columns are untouched and the new one is appended at the end.

### Example — a blocked change (removing a column)

```sql
CREATE OR REPLACE VIEW photo_stats AS
SELECT p.id, p.url, COUNT(DISTINCT l.id) AS like_count   -- hashtags column gone
FROM photos AS p
LEFT JOIN likes AS l ON l.photo_id = p.id
GROUP BY p.id, p.url;
```

**Result:** Rejected.
```
ERROR:  cannot drop columns from view
```

### ⚠️ Traps

- **Trying to remove or reorder a view's existing columns with `CREATE OR REPLACE`.** It's not allowed, ever — something referencing the view by column position or name could break silently otherwise. `DROP VIEW photo_stats;` followed by a fresh `CREATE VIEW` is the actual way to reshape one.

---

## 4. When to use a view

**What it is:** A tool for **reuse and clarity** — not a performance optimization.

**Why it exists:** `photo_stats` hides four joins and a `GROUP BY` behind one name. Every place that needs "photo, with its stats" now says so directly, instead of repeating (and risking a subtly different copy of) the same query.

| Good fit | Not a fit |
|---|---|
| A complex query used in more than one place | Speeding up a slow query — it still runs the real query every time (section 28 is for caching) |
| Hiding join complexity behind a clear name | Data that needs to survive as a genuine snapshot in time |
| A stable "shape" for something computed, reused across many ad-hoc queries | Restricting which *rows* a query sees without also restricting columns — views can help, but that's a permissions topic beyond this course |

### ⚠️ Traps

- **Reaching for a view because a query "feels slow."** A view changes nothing about the underlying work — it's the exact same joins and aggregation, run just as often, wearing a shorter name. If repeated computation is the actual problem, that's [28 · Optimizing Queries with Materialized Views](../28-optimizing-queries-with-materialized-views/README.md), a genuinely different tool.

---

## Recap

| Concept | What it means |
|---|---|
| View | A saved `SELECT`, queried like a table, re-run fresh every time |
| `CREATE VIEW` | Names a query for reuse across every future query, not just one |
| `CREATE OR REPLACE VIEW` | Can change logic or add trailing columns; can't remove or reorder existing ones |
| `DROP VIEW` | The way to actually reshape a view's column list |
| Good use case | Reuse and clarity |
| Not a use case | Performance — a view has zero caching |

> **The one thing I want to remember:** a view is a name for a query, not a copy of its result. Every read runs the real thing, every time — which is exactly why it can never be a performance fix on its own.

---

## Practice

**1.** Create a view `user_activity` showing each user's `photo_count` and `follower_count`, reusing the query from section 20's first worked example.

<details>
<summary>Show answer</summary>

```sql
CREATE VIEW user_activity AS
SELECT u.username,
       COUNT(DISTINCT p.id) AS photo_count,
       COUNT(DISTINCT f.follower_id) AS follower_count
FROM users AS u
LEFT JOIN photos AS p    ON p.user_id = u.id
LEFT JOIN followers AS f ON f.followed_id = u.id
GROUP BY u.username;
```

</details>

**2.** After creating `photo_stats`, `bella` likes `coffee.jpg` (photo `103`). Without re-running `CREATE VIEW`, what does `SELECT like_count FROM photo_stats WHERE url = 'https://example.com/coffee.jpg';` return?

<details>
<summary>Show answer</summary>

**`1`** — the new like immediately shows up, since the view re-runs its query on every access rather than returning a stored result from when it was created.

</details>

**3.** Why can't `CREATE OR REPLACE VIEW photo_stats AS SELECT p.url, p.id, ... FROM photos p ...;` (swapping the first two column's order) just be treated the same as adding a new column at the end?

<details>
<summary>Show answer</summary>

Reordering existing columns changes what "column 1" and "column 2" mean to anything already referencing the view by position — Postgres treats that identically to removing a column, for the same reason: it could silently break something downstream. Appending a genuinely *new* column at the end doesn't touch any existing position.

</details>

---

## What confused me

- I expected `CREATE VIEW` to save the *result*, the way I'd save a file. Realizing it saves the *query* — re-run in full on every access — was the moment "a view isn't a performance tool" stopped being a rule to memorize and started being obvious.
- The "can't drop columns" restriction on `CREATE OR REPLACE VIEW` felt arbitrary until I considered something else already querying specific columns from it — reordering or removing one is indistinguishable, from the outside, from breaking that contract.
- I initially reached for a view specifically because a query felt slow to type out repeatedly. It fixed the *typing*, not the *running* — the query underneath was exactly as much work as before, every single time.

---

[⬅ 26 · Recursive Common Table Expressions](../26-recursive-common-table-expressions/README.md) · [🏠 Index](../README.md) · [28 · Optimizing Queries with Materialized Views ➡](../28-optimizing-queries-with-materialized-views/README.md)
